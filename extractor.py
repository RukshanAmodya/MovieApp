import asyncio
import sys
import os
import re
import uuid
import argparse
from playwright.async_api import async_playwright

# Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, db

# Reconfigure stdout to support unicode printing on Windows console
if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except AttributeError:
        pass

# ──────────────────────────────────────────────
# Firebase Helpers
# ──────────────────────────────────────────────

SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(__file__), "rooflix-app-firebase-adminsdk-fbsvc-a93c6036a4.json")
FIREBASE_DB_URL = "https://rooflix-app-default-rtdb.firebaseio.com"
CS06_DOMAIN = "https://cs06.avatarzone.online"

def init_firebase():
    """Initialize Firebase app once. Returns (movies_ref, processed_ref)."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_DB_URL})
    return db.reference("movies"), db.reference("_processed")


def load_processed_urls(processed_ref) -> set:
    """
    Read already-scraped movie URLs from the _processed Firebase node.
    This is separate from movies data so movies stays clean.
    """
    print("[*] Loading processed URLs from Firebase for deduplication...")
    try:
        snapshot = processed_ref.get()
        if not snapshot:
            print("[*] No processed URLs found. Starting fresh.")
            return set()
        # Keys are base64-encoded movie URLs stored as True
        urls = set(snapshot.keys())
        print(f"[+] Found {len(urls)} already-processed movie(s).")
        return urls
    except Exception as e:
        print(f"[!] Warning: could not read Firebase _processed: {e}")
        return set()

def save_to_firebase(movies_ref, processed_ref, movie_url: str,
                     title: str, cover_url: str, stream_url: str):
    """Write movie to Firebase with UUID key. Track URL in _processed for dedup."""
    key = str(uuid.uuid4())
    # Save clean movie data
    movies_ref.child(key).set({
        "title": title,
        "cover_url": cover_url,
        "stream_url": stream_url,
    })
    # Mark as processed using a sanitized URL key
    processed_key = re.sub(r"[.#$\[\]/]", "_", movie_url)[-150:]
    processed_ref.child(processed_key).set(True)
    return key

# ──────────────────────────────────────────────
# Scraper Functions
# ──────────────────────────────────────────────

async def get_movie_list(page, base_url, verbose=False):
    if verbose:
        print(f"[*] Fetching movie catalog from: {base_url}")

    try:
        for attempt in range(3):
            try:
                response = await page.goto(base_url, wait_until="domcontentloaded", timeout=60000)
                if response and response.status == 404:
                    if verbose:
                        print(f"[-] Catalog page returned 404: {base_url}")
                    return []
                break
            except Exception as goto_err:
                if attempt == 2:
                    raise goto_err
                print(f"[!] Warning: catalog navigation attempt {attempt+1} failed. Retrying...")
                await page.wait_for_timeout(3000)

        await page.wait_for_timeout(2500)

        anchors = await page.locator("a").all()
        movie_links = []

        for anchor in anchors:
            try:
                href = await anchor.get_attribute("href")
                title = await anchor.get_attribute("title") or await anchor.inner_text()
                title = title.strip()

                if href:
                    clean_href = href.split('?')[0].split('#')[0]
                    if ("/movies/" in clean_href
                            and clean_href.rstrip('/') != "https://cinesubz.lk/movies"
                            and "/page/" not in clean_href):
                        if clean_href not in [link[0] for link in movie_links]:
                            movie_links.append((clean_href, title or "Unknown Movie"))
            except Exception:
                continue

        if verbose:
            print(f"[+] Found {len(movie_links)} movie link(s) on page.")
        return movie_links

    except Exception as e:
        if verbose:
            print(f"[-] Error loading catalog page: {e}")
        return []


async def extract_stream_urls(page, movie_url, verbose=False):
    if verbose:
        print(f"\n[*] Processing movie: {movie_url}")

    extracted_urls = {}
    cover_image_url = ""

    try:
        for attempt in range(3):
            try:
                await page.goto(movie_url, wait_until="domcontentloaded", timeout=60000)
                break
            except Exception as e:
                if attempt == 2:
                    raise e
                print(f"    [!] Navigation failed. Retry {attempt+1}...")
                await page.wait_for_timeout(3000)

        await page.wait_for_timeout(2000)

        # Extract cover image URL via og:image metadata
        og_image = page.locator('meta[property="og:image"]')
        if await og_image.count() > 0:
            cover_image_url = await og_image.first.get_attribute("content") or ""
            if verbose and cover_image_url:
                print(f"    [+] Found Cover Image: {cover_image_url}")

        # 1. Click splash-play button first to initialize player
        splash_play = page.locator("#splash-play")
        if await splash_play.count() > 0 and await splash_play.is_visible():
            if verbose:
                print("    [*] Clicking #splash-play to initialize player...")
            try:
                await splash_play.click(timeout=5000)
                await page.wait_for_timeout(3000)
            except Exception as click_err:
                if verbose:
                    print(f"    [!] Error clicking splash-play: {click_err}")

        # 2. Look for option tabs (Zetaflix/Dooplay servers)
        server_options = await page.locator("#playeroptions li").all()

        if not server_options:
            iframes = await page.locator("iframe").all()
            for iframe in iframes:
                try:
                    src = await iframe.get_attribute("src")
                    iframe_id = await iframe.get_attribute("id")
                    if src and "youtube.com" not in src and src not in ("null", "", None) and iframe_id != "trailer-view":
                        video_url = src
                        try:
                            el_handle = await iframe.element_handle()
                            content_frame = await el_handle.content_frame() if el_handle else None
                            if content_frame:
                                video_el = content_frame.locator("video.art-video, video")
                                await video_el.first.wait_for(state="attached", timeout=6000)
                                direct_src = await video_el.first.get_attribute("src")
                                if direct_src:
                                    video_url = direct_src
                        except Exception:
                            pass
                        extracted_urls["Stream Player"] = video_url
                        break
                except Exception:
                    continue
        else:
            if verbose:
                print(f"    [*] Found {len(server_options)} player options. Extracting streams...")

            for opt in server_options:
                opt_text_clean = ""
                try:
                    opt_text = await opt.inner_text()
                    opt_text_clean = opt_text.replace("\n", " ").strip()

                    if "trailer" in opt_text_clean.lower() or "youtube" in opt_text_clean.lower():
                        continue

                    if verbose:
                        print(f"    [*] Clicking player option: '{opt_text_clean}'")

                    await opt.click(timeout=5000)
                    await page.wait_for_timeout(4500)

                    iframes = await page.locator("iframe").all()
                    for iframe in iframes:
                        src = await iframe.get_attribute("src")
                        iframe_id = await iframe.get_attribute("id")

                        if src and "youtube.com" not in src and src not in ("null", "", None) and iframe_id != "trailer-view":
                            video_url = src
                            try:
                                el_handle = await iframe.element_handle()
                                content_frame = await el_handle.content_frame() if el_handle else None
                                if content_frame:
                                    video_el = content_frame.locator("video.art-video, video")
                                    await video_el.first.wait_for(state="attached", timeout=5000)
                                    direct_src = await video_el.first.get_attribute("src")
                                    if direct_src:
                                        video_url = direct_src
                            except Exception:
                                pass

                            extracted_urls[opt_text_clean] = video_url
                            if verbose:
                                print(f"      [+] Found URL for {opt_text_clean}: {video_url}")
                            break
                except Exception as click_err:
                    if verbose:
                        print(f"      [-] Error clicking option '{opt_text_clean}': {click_err}")

        return extracted_urls, cover_image_url

    except Exception as e:
        if verbose:
            print(f"    [-] Error processing page: {e}")
        return {}, ""


# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────

async def main():
    parser = argparse.ArgumentParser(description="Endless movie crawler bot for cinesubz.lk → Firebase")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print verbose logs")
    args = parser.parse_args()

    # Connect to Firebase
    print("[*] Connecting to Firebase Realtime Database...")
    movies_ref, processed_ref = init_firebase()
    print(f"[+] Connected: {FIREBASE_DB_URL}/movies")

    # Load already-processed URL keys to skip duplicates
    processed_urls = load_processed_urls(processed_ref)

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )

        page = await context.new_page()
        # Auto-close popup tabs to block ad redirects
        page.on("popup", lambda p: asyncio.create_task(p.close()))

        page_num = 1
        consecutive_empty_pages = 0

        while True:
            if page_num == 1:
                catalog_url = "https://cinesubz.lk/movies/"
            else:
                catalog_url = f"https://cinesubz.lk/movies/page/{page_num}/"

            print(f"\n==========================================")
            print(f"[*] Bot Crawling Listing Page {page_num}: {catalog_url}")
            print(f"==========================================")

            movie_list = await get_movie_list(page, catalog_url, args.verbose)

            if not movie_list:
                consecutive_empty_pages += 1
                if consecutive_empty_pages >= 2:
                    print(f"\n[*] Consecutively found empty pages (Page {page_num}). Reached the final page!")
                    break
                page_num += 1
                continue

            consecutive_empty_pages = 0
            print(f"[*] Listing Page {page_num} contains {len(movie_list)} movies.")

            for idx, (movie_url, title) in enumerate(movie_list, 1):
                # Skip duplicates
                if movie_url in processed_urls:
                    if args.verbose:
                        print(f"[Page {page_num} - {idx}/{len(movie_list)}] Skipped (already in Firebase): '{title}'")
                    continue

                print(f"[Page {page_num} - {idx}/{len(movie_list)}] Scraping: '{title}'")
                urls_dict, cover_image_url = await extract_stream_urls(page, movie_url, args.verbose)

                # Filter: only keep URLs from cs06.avatarzone.online
                filtered_urls = [v for v in urls_dict.values() if v.startswith(CS06_DOMAIN)]

                if not filtered_urls:
                    print(f"    [-] No cs06 stream found for '{title}'. Skipping.")
                    # Mark as processed even if skipped (no cs06 URL)
                    processed_key = re.sub(r"[.#$\[\]/]", "_", movie_url)[-150:]
                    try:
                        processed_ref.child(processed_key).set(True)
                    except Exception:
                        pass
                    processed_urls.add(processed_key)
                    continue

                # Take the first cs06 URL
                stream_url = filtered_urls[0]

                # Save to Firebase with UUID key
                try:
                    saved_key = save_to_firebase(
                        movies_ref,
                        processed_ref,
                        movie_url=movie_url,
                        title=title,
                        cover_url=cover_image_url,
                        stream_url=stream_url,
                    )
                    print(f"    [+] Saved to Firebase [{saved_key}]")
                except Exception as fb_err:
                    print(f"    [!] Firebase write error: {fb_err}")


                processed_urls.add(movie_url)

            page_num += 1

        print(f"\n[+] Crawl complete! All movies saved to Firebase: {FIREBASE_DB_URL}/movies")
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
