import asyncio
import sys
import os
import re
import uuid
import time
import logging
import argparse
import traceback
from playwright.async_api import async_playwright, Error as PlaywrightError

# Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, db

# ──────────────────────────────────────────────
# Stdout / Logging Setup
# ──────────────────────────────────────────────

if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except AttributeError:
        pass

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("bot_errors.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("crawler")

# ──────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────

SERVICE_ACCOUNT_PATH = os.path.join(
    os.path.dirname(__file__),
    "rooflix-app-firebase-adminsdk-fbsvc-a93c6036a4.json"
)
FIREBASE_DB_URL  = "https://rooflix-app-default-rtdb.firebaseio.com"
CS06_DOMAIN      = "https://cs06.avatarzone.online"
BASE_CATALOG_URL = "https://cinesubz.lk/movies/"

MAX_RETRIES          = 4      # retries per network/firebase op
BACKOFF_BASE         = 2      # seconds (doubles each retry)
MAX_CONSECUTIVE_ERRS = 5      # consecutive movie errors before long pause
CONSECUTIVE_ERR_WAIT = 60     # seconds to wait after too many errors
PAGE_LOAD_WAIT       = 2500   # ms after page load
PLAYER_CLICK_WAIT    = 4500   # ms after clicking a server option

# ──────────────────────────────────────────────
# Retry Helper
# ──────────────────────────────────────────────

async def with_retry(coro_fn, label="operation", retries=MAX_RETRIES, base=BACKOFF_BASE):
    """
    Retry an async coroutine with exponential backoff.
    coro_fn must be a zero-argument callable that returns a coroutine.
    """
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            return await coro_fn()
        except Exception as e:
            last_err = e
            wait = base ** attempt
            log.warning(f"  [Retry {attempt}/{retries}] {label} failed: {e}. Waiting {wait}s...")
            await asyncio.sleep(wait)
    raise last_err

def firebase_retry(fn, label="Firebase op", retries=MAX_RETRIES, base=BACKOFF_BASE):
    """
    Retry a synchronous Firebase call with exponential backoff.
    """
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            return fn()
        except Exception as e:
            last_err = e
            wait = base ** attempt
            log.warning(f"  [FB Retry {attempt}/{retries}] {label} failed: {e}. Waiting {wait}s...")
            time.sleep(wait)
    raise last_err

# ──────────────────────────────────────────────
# Firebase
# ──────────────────────────────────────────────

def init_firebase():
    """Initialize Firebase and return (movies_ref, processed_ref)."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred, {"databaseURL": FIREBASE_DB_URL})
    return db.reference("movies"), db.reference("_processed")

def load_processed_urls(processed_ref) -> set:
    """Load already-scraped URL keys from _processed node for deduplication."""
    log.info("[*] Loading processed URLs from Firebase...")
    try:
        snapshot = firebase_retry(lambda: processed_ref.get(), "load _processed")
        if not snapshot:
            log.info("[*] No processed URLs found. Starting fresh.")
            return set()
        urls = set(snapshot.keys())
        log.info(f"[+] Found {len(urls)} already-processed movie(s). These will be skipped.")
        return urls
    except Exception as e:
        log.error(f"[!] Could not load _processed from Firebase: {e}. Continuing without dedup cache.")
        return set()

def save_to_firebase(movies_ref, processed_ref, movie_url: str,
                     title: str, cover_url: str, stream_url: str) -> str:
    """Save a movie to Firebase with a UUID key and mark it as processed."""
    key = str(uuid.uuid4())
    processed_key = re.sub(r"[.#$\[\]/]", "_", movie_url)[-150:]

    def _write():
        movies_ref.child(key).set({
            "title":      title,
            "cover_url":  cover_url,
            "stream_url": stream_url,
        })
        processed_ref.child(processed_key).set(True)

    firebase_retry(_write, f"save '{title}'")
    return key, processed_key

def mark_processed(processed_ref, movie_url: str) -> str:
    """Mark a movie URL as processed (e.g. when skipped due to no cs06 stream)."""
    processed_key = re.sub(r"[.#$\[\]/]", "_", movie_url)[-150:]
    try:
        firebase_retry(lambda: processed_ref.child(processed_key).set(True), "mark processed")
    except Exception as e:
        log.warning(f"  [!] Could not mark URL as processed in Firebase: {e}")
    return processed_key

# ──────────────────────────────────────────────
# Browser Factory
# ──────────────────────────────────────────────

async def create_browser_context(playwright):
    """Launch a fresh Chromium browser + context."""
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context(
        user_agent=(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        )
    )
    page = await context.new_page()
    page.on("popup", lambda p: asyncio.create_task(p.close()))
    return browser, page

# ──────────────────────────────────────────────
# Scrapers
# ──────────────────────────────────────────────

async def get_movie_list(page, base_url, verbose=False):
    """Fetch movie links from a catalog page. Returns list of (url, title)."""
    if verbose:
        log.info(f"[*] Fetching catalog: {base_url}")

    async def _navigate():
        response = await page.goto(base_url, wait_until="domcontentloaded", timeout=60000)
        if response and response.status == 404:
            return None  # signal 404
        return response

    try:
        resp = await with_retry(_navigate, f"catalog page {base_url}")
        if resp is None:
            log.info(f"[-] 404 on catalog page: {base_url}")
            return []

        await page.wait_for_timeout(PAGE_LOAD_WAIT)

        anchors = await page.locator("a").all()
        movie_links = []
        seen = set()

        for anchor in anchors:
            try:
                href  = await anchor.get_attribute("href")
                title = (await anchor.get_attribute("title") or await anchor.inner_text()).strip()
                if not href:
                    continue
                clean = href.split('?')[0].split('#')[0]
                if (
                    "/movies/" in clean
                    and clean.rstrip('/') != "https://cinesubz.lk/movies"
                    and "/page/" not in clean
                    and clean not in seen
                ):
                    movie_links.append((clean, title or "Unknown Movie"))
                    seen.add(clean)
            except Exception:
                continue

        if verbose:
            log.info(f"[+] Found {len(movie_links)} movie link(s) on page.")
        return movie_links

    except Exception as e:
        log.error(f"[!] Error loading catalog page {base_url}: {e}")
        return []


async def extract_stream_urls(page, movie_url, verbose=False):
    """
    Navigate to a movie page and extract:
      - cover image URL (og:image)
      - stream URLs per player server
    Returns (dict_of_streams, cover_image_url).
    """
    if verbose:
        log.info(f"\n[*] Processing: {movie_url}")

    extracted_urls = {}
    cover_image_url = ""

    async def _navigate():
        await page.goto(movie_url, wait_until="domcontentloaded", timeout=60000)

    try:
        await with_retry(_navigate, f"navigate to {movie_url}")
        await page.wait_for_timeout(PAGE_LOAD_WAIT)

        # Cover image
        try:
            og = page.locator('meta[property="og:image"]')
            if await og.count() > 0:
                cover_image_url = await og.first.get_attribute("content") or ""
                if verbose and cover_image_url:
                    log.info(f"    [+] Cover Image: {cover_image_url}")
        except Exception as e:
            log.warning(f"    [!] Could not extract cover image: {e}")

        # Click splash-play
        try:
            splash = page.locator("#splash-play")
            if await splash.count() > 0 and await splash.is_visible():
                if verbose:
                    log.info("    [*] Clicking #splash-play...")
                await splash.click(timeout=5000)
                await page.wait_for_timeout(3000)
        except Exception as e:
            if verbose:
                log.warning(f"    [!] splash-play click failed: {e}")

        # Server options
        server_options = await page.locator("#playeroptions li").all()

        if not server_options:
            # Fallback: look for a bare iframe
            iframes = await page.locator("iframe").all()
            for iframe in iframes:
                try:
                    src      = await iframe.get_attribute("src")
                    ifrm_id  = await iframe.get_attribute("id")
                    if src and "youtube.com" not in src and src not in ("null", "", None) and ifrm_id != "trailer-view":
                        video_url = src
                        try:
                            el_handle    = await iframe.element_handle()
                            content_frame = await el_handle.content_frame() if el_handle else None
                            if content_frame:
                                vel = content_frame.locator("video.art-video, video")
                                await vel.first.wait_for(state="attached", timeout=6000)
                                direct = await vel.first.get_attribute("src")
                                if direct:
                                    video_url = direct
                        except Exception:
                            pass
                        extracted_urls["Stream Player"] = video_url
                        break
                except Exception:
                    continue
        else:
            if verbose:
                log.info(f"    [*] {len(server_options)} player option(s) found.")

            for opt in server_options:
                opt_text_clean = ""
                try:
                    opt_text_clean = (await opt.inner_text()).replace("\n", " ").strip()
                    if "trailer" in opt_text_clean.lower() or "youtube" in opt_text_clean.lower():
                        continue
                    if verbose:
                        log.info(f"    [*] Clicking: '{opt_text_clean}'")

                    await opt.click(timeout=5000)
                    await page.wait_for_timeout(PLAYER_CLICK_WAIT)

                    iframes = await page.locator("iframe").all()
                    for iframe in iframes:
                        try:
                            src     = await iframe.get_attribute("src")
                            ifrm_id = await iframe.get_attribute("id")
                            if src and "youtube.com" not in src and src not in ("null", "", None) and ifrm_id != "trailer-view":
                                video_url = src
                                try:
                                    el_handle    = await iframe.element_handle()
                                    content_frame = await el_handle.content_frame() if el_handle else None
                                    if content_frame:
                                        vel = content_frame.locator("video.art-video, video")
                                        await vel.first.wait_for(state="attached", timeout=5000)
                                        direct = await vel.first.get_attribute("src")
                                        if direct:
                                            video_url = direct
                                except Exception:
                                    pass
                                extracted_urls[opt_text_clean] = video_url
                                if verbose:
                                    log.info(f"      [+] {opt_text_clean}: {video_url}")
                                break
                        except Exception:
                            continue
                except PlaywrightError as pe:
                    log.warning(f"      [-] Playwright error on '{opt_text_clean}': {pe}")
                except Exception as e:
                    log.warning(f"      [-] Error on '{opt_text_clean}': {e}")

        return extracted_urls, cover_image_url

    except Exception as e:
        log.error(f"    [!] Fatal error processing {movie_url}: {e}")
        return {}, ""

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────

async def main():
    parser = argparse.ArgumentParser(description="Endless movie crawler → Firebase")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    # ── Firebase ──────────────────────────────
    log.info("[*] Connecting to Firebase Realtime Database...")
    try:
        movies_ref, processed_ref = init_firebase()
        log.info(f"[+] Firebase connected: {FIREBASE_DB_URL}/movies")
    except Exception as e:
        log.critical(f"[!!] Cannot connect to Firebase: {e}")
        sys.exit(1)

    processed_urls = load_processed_urls(processed_ref)

    # ── Crawler ───────────────────────────────
    async with async_playwright() as playwright:
        browser, page = await create_browser_context(playwright)
        log.info("[+] Browser launched.")

        page_num           = 1
        consecutive_empty  = 0
        consecutive_errors = 0  # tracks movie-level errors in a row

        try:
            while True:
                catalog_url = BASE_CATALOG_URL if page_num == 1 else f"{BASE_CATALOG_URL}page/{page_num}/"

                log.info(f"\n==========================================")
                log.info(f"[*] Listing Page {page_num}: {catalog_url}")
                log.info(f"==========================================")

                # ── Fetch movie list ──────────────────────
                try:
                    movie_list = await get_movie_list(page, catalog_url, args.verbose)
                except Exception as e:
                    log.error(f"[!] Unhandled error fetching catalog page {page_num}: {e}")
                    log.debug(traceback.format_exc())
                    page_num += 1
                    continue

                if not movie_list:
                    consecutive_empty += 1
                    if consecutive_empty >= 2:
                        log.info(f"\n[*] Two consecutive empty pages. Crawl complete!")
                        break
                    page_num += 1
                    continue

                consecutive_empty = 0
                log.info(f"[*] Page {page_num}: {len(movie_list)} movies found.")

                # ── Process each movie ────────────────────
                for idx, (movie_url, title) in enumerate(movie_list, 1):
                    # Dedup check
                    processed_key_check = re.sub(r"[.#$\[\]/]", "_", movie_url)[-150:]
                    if processed_key_check in processed_urls:
                        if args.verbose:
                            log.info(f"[Page {page_num} - {idx}/{len(movie_list)}] Already in Firebase, skipping: '{title}'")
                        continue

                    log.info(f"[Page {page_num} - {idx}/{len(movie_list)}] Scraping: '{title}'")

                    try:
                        urls_dict, cover_image_url = await extract_stream_urls(page, movie_url, args.verbose)

                        # Filter to cs06 only
                        filtered = [v for v in urls_dict.values() if v.startswith(CS06_DOMAIN)]

                        if not filtered:
                            log.info(f"    [-] No cs06 stream. Skipping: '{title}'")
                            pkey = mark_processed(processed_ref, movie_url)
                            processed_urls.add(pkey)
                            consecutive_errors = 0  # skipping is not an error
                            continue

                        stream_url = filtered[0]

                        # Save
                        saved_key, pkey = save_to_firebase(
                            movies_ref, processed_ref, movie_url,
                            title=title,
                            cover_url=cover_image_url,
                            stream_url=stream_url,
                        )
                        processed_urls.add(pkey)
                        log.info(f"    [+] Saved → Firebase [{saved_key}]")
                        consecutive_errors = 0  # reset on success

                    except PlaywrightError as pe:
                        consecutive_errors += 1
                        log.error(f"    [!!] Playwright error on '{title}': {pe}")
                        log.debug(traceback.format_exc())

                        # Try to recover the browser if it has crashed
                        try:
                            await page.reload(timeout=10000)
                        except Exception:
                            log.warning("    [!] Page reload failed. Restarting browser...")
                            try:
                                await browser.close()
                            except Exception:
                                pass
                            browser, page = await create_browser_context(playwright)
                            log.info("    [+] Browser restarted.")

                    except Exception as e:
                        consecutive_errors += 1
                        log.error(f"    [!!] Error on '{title}': {e}")
                        log.debug(traceback.format_exc())

                    finally:
                        # Circuit breaker: too many errors in a row → pause
                        if consecutive_errors >= MAX_CONSECUTIVE_ERRS:
                            log.warning(
                                f"\n[!!] {consecutive_errors} consecutive errors detected. "
                                f"Pausing {CONSECUTIVE_ERR_WAIT}s before continuing..."
                            )
                            await asyncio.sleep(CONSECUTIVE_ERR_WAIT)
                            consecutive_errors = 0

                page_num += 1

        except KeyboardInterrupt:
            log.info("\n[*] Interrupted by user (Ctrl+C). Shutting down gracefully...")

        except Exception as e:
            log.critical(f"\n[!!] Unexpected top-level crash: {e}")
            log.critical(traceback.format_exc())

        finally:
            try:
                await browser.close()
                log.info("[+] Browser closed.")
            except Exception:
                pass

    log.info(f"\n[+] Crawl finished. All data saved to: {FIREBASE_DB_URL}/movies")


if __name__ == "__main__":
    asyncio.run(main())
