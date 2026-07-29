# MovieApp Scraper Bot

This repository contains a Python-based automated web scraper bot designed to crawl movie listings on `cinesubz.lk` and extract direct video stream URLs inside player options.

## Features
- **Pagination Support**: Automatically crawls multiple listing pages consecutively.
- **Direct Stream Extraction**: Extracts direct `.mp4` URLs inside players (e.g. CS Player) using Playwright frame content selector.
- **Auto Saving**: Stores results to a CSV file dynamically.

## Installation

Ensure you have Python installed, then set up the required browser automation libraries:

```bash
# 1. Install playwright package
pip install playwright

# 2. Download and install chromium browser binaries
playwright install chromium
```

## Usage

Run the crawler with:

```bash
python extractor.py --pages 2 -v
```

### Arguments
- `--pages <number>`: Number of listing pages to crawl. Set to `0` to crawl all available pages indefinitely. (Default is `1`).
- `--output <filename>`: Custom path to save the output CSV. (Default is `movies_stream_urls.csv`).
- `-v`, `--verbose`: Enable verbose logging to see step-by-step progress.
