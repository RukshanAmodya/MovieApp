import asyncio
import sys
import csv
import os
import argparse
from playwright.async_api import async_playwright

# Reconfigure stdout to support unicode printing on Windows console
if sys.platform.startswith("win"):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except AttributeError:
        pass

async def get_movie_list(page, base_url, verbose=False):
    if verbose:
        print(f"[*] Fetching movie catalog from: {base_url}")
        
    try:
        # standard navigation with retries
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
        
        # Locate movie links in grid/listing
        anchors = await page.locator("a").all()
        movie_links = []
        
        for anchor in anchors:
            try:
                href = await anchor.get_attribute("href")
                title = await anchor.get_attribute("title") or await anchor.inner_text()
                title = title.strip()
                
                if href:
                    clean_href = href.split('?')[0].split('#')[0]
                    if "/movies/" in clean_href and clean_href.rstrip('/') != "https://cinesubz.lk/movies" and not "/page/" in clean_href:
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
        # Load movie page with retries
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
            # Fallback if no server tabs exist
            iframes = await page.locator("iframe").all()
            for idx, iframe in enumerate(iframes):
                try:
                    src = await iframe.get_attribute("src")
                    iframe_id = await iframe.get_attribute("id")
                    if src and "youtube.com" not in src and src != "null" and src != "" and iframe_id != "trailer-view":
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
                
            for idx, opt in enumerate(server_options):
                try:
                    opt_text = await opt.inner_text()
                    opt_text_clean = opt_text.replace("\n", " ").strip()
                    
                    # Exclude trailers
                    if "trailer" in opt_text_clean.lower() or "youtube" in opt_text_clean.lower():
                        continue
                        
                    if verbose:
                        print(f"    [*] Clicking player option: '{opt_text_clean}'")
                        
                    await opt.click(timeout=5000)
                    # Wait for iframe load
                    await page.wait_for_timeout(4500)
                    
                    iframes = await page.locator("iframe").all()
                    for iframe in iframes:
                        src = await iframe.get_attribute("src")
                        iframe_id = await iframe.get_attribute("id")
                        
                        if src and "youtube.com" not in src and src != "null" and src != "" and iframe_id != "trailer-view":
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
                        
        if extracted_urls:
            return extracted_urls, cover_image_url
        else:
            return {"Status": "NO_STREAMS_FOUND"}, cover_image_url
            
    except Exception as e:
        if verbose:
            print(f"    [-] Error processing page: {e}")
        return {"Status": f"ERROR: {str(e)}"}, ""

async def main():
    parser = argparse.ArgumentParser(description="Endless movie crawler bot for cinesubz.lk")
    parser.add_argument("--output", default="movies_stream_urls.csv", help="The output CSV file path")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print verbose logs")
    args = parser.parse_args()

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        # Using desktop User-Agent
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        
        page = await context.new_page()
        
        # Auto-close popup tabs to block ad redirects
        page.on("popup", lambda p: asyncio.create_task(p.close()))
        
        csv_file_path = args.output
        file_exists = os.path.exists(csv_file_path)
        headers = ["Title", "Movie Page URL", "Cover Image URL", "Extracted Stream URLs"]
        
        # Load already processed URLs to avoid scraping duplicates if rerun
        processed_urls = set()
        if file_exists:
            try:
                with open(csv_file_path, mode="r", encoding="utf-8") as rf:
                    reader = csv.reader(rf)
                    # skip header
                    next(reader, None)
                    for row in reader:
                        if len(row) > 1:
                            processed_urls.add(row[1])
            except Exception as err:
                print(f"[!] Warning reading existing CSV: {err}")

        with open(csv_file_path, mode="a", encoding="utf-8", newline="") as csv_file:
            writer = csv.writer(csv_file)
            if not file_exists:
                writer.writerow(headers)
            
            page_num = 1
            consecutive_empty_pages = 0
            
            while True:
                # Construct page URL
                if page_num == 1:
                    catalog_url = "https://cinesubz.lk/movies/"
                else:
                    catalog_url = f"https://cinesubz.lk/movies/page/{page_num}/"
                
                print(f"\n==========================================")
                print(f"[*] Bot Crawling Listing Page {page_num}: {catalog_url}")
                print(f"==========================================")
                
                # Fetch movie list for this listing page
                movie_list = await get_movie_list(page, catalog_url, args.verbose)
                
                # If page contains no movies, retry once or check if we are at the end
                if not movie_list:
                    consecutive_empty_pages += 1
                    if consecutive_empty_pages >= 2:
                        print(f"\n[*] Consecutively found empty pages (Page {page_num}). Reached the final page!")
                        break
                    page_num += 1
                    continue
                
                # Reset counter when we find movies
                consecutive_empty_pages = 0
                print(f"[*] Listing Page {page_num} contains {len(movie_list)} movies.")
                
                for idx, (movie_url, title) in enumerate(movie_list, 1):
                    # Check if already processed
                    if movie_url in processed_urls:
                        if args.verbose:
                            print(f"[Page {page_num} - {idx}/{len(movie_list)}] Skipped (already processed): '{title}'")
                        continue
                        
                    print(f"[Page {page_num} - {idx}/{len(movie_list)}] Scraped: '{title}'")
                    urls_dict, cover_image_url = await extract_stream_urls(page, movie_url, args.verbose)
                    
                    # Filter: only keep URLs from cs06.avatarzone.online
                    CS06_DOMAIN = "https://cs06.avatarzone.online"
                    filtered_urls = {k: v for k, v in urls_dict.items() if v.startswith(CS06_DOMAIN)}
                    
                    # Skip this movie if no cs06 URLs were found
                    if not filtered_urls:
                        print(f"    [-] No cs06 stream found for '{title}'. Skipping.")
                        processed_urls.add(movie_url)
                        continue
                    
                    # Format output string (only cs06 URLs)
                    urls_str = "; ".join([f"{k}: {v}" for k, v in filtered_urls.items()])
                    
                    # Save immediately to prevent data loss
                    writer.writerow([title, movie_url, cover_image_url, urls_str])
                    csv_file.flush()
                    processed_urls.add(movie_url)
                
                page_num += 1
                
        print(f"\n[+] Scrape execution complete! Saved output: {os.path.abspath(csv_file_path)}")
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
