# Antigravity & Hermes — Watch Next

A personal watch-tracker and recommender for **Antigravity** and **Hermes**
content across **YouTube, podcasts, and the web**. It shows you what to watch
next, and when you mark something watched it asks whether you **liked it** —
then uses your 👍 / 👎 to sharpen future picks.

![screenshot](docs/screenshot.png)

## How it works

```
 sources.json ──► fetch_media.py ──► catalog.json ──► web app (Up Next / Browse / Library / Stats)
   (where to look)   (aggregator)     (the content)     (recommends + records watched/liked)
```

- **No backend, no database.** The web app is static HTML/CSS/JS. Your
  watched/liked history is stored in your browser's `localStorage`, so it stays
  on your device.
- **The recommender** ranks unwatched items by your taste: topics, sources, and
  creators you've 👍'd score higher; 👎'd ones score lower; newer items get a
  recency boost. The top pick appears as the **Up Next** hero with a short
  "recommended because…" explanation.
- **The watched → liked loop:** mark an item watched (on the hero or any card)
  and it moves to your **Library** with a "Did you like it?" prompt. Rating it
  feeds straight back into the ranking.

## Quick start

The app must be served over HTTP (browsers block `fetch` of local files over
`file://`).

```bash
# from the repo root
python3 -m http.server 8000
# then open http://localhost:8000/web/
```

or use the helper:

```bash
./scripts/serve.sh        # serves on http://localhost:8000/web/
```

It ships with **seed data** (real YouTube/web *search* links) so it works
immediately. Run the fetcher to replace it with live content.

## Pulling live content

1. Edit **`data/sources.json`**:
   - `youtube.search_terms` / `youtube.channel_ids` — what to index on YouTube
   - `podcasts.feeds` — podcast RSS feed URLs
   - `websites.pages` — pages to scrape links from (with an optional CSS-ish hint)
   - `match` — regexes that tag an item as **Antigravity** and/or **Hermes**
2. For YouTube, get a free **YouTube Data API v3** key
   (Google Cloud Console → APIs & Services → enable *YouTube Data API v3* →
   create an API key) and export it:
   ```bash
   export YOUTUBE_API_KEY=your_key_here
   ```
3. Run the fetcher (Python 3.9+, **no third-party packages required**):
   ```bash
   python3 scripts/fetch_media.py
   ```
   It writes `data/catalog.json`. Reload the web app to see the new items.

Each source degrades gracefully — a missing API key or an unreachable feed is
skipped with a warning, and the other sources still run.

### Keep it fresh automatically

Run the fetcher on a schedule, e.g. a cron entry:

```cron
0 8 * * *  cd /path/to/antigravity-hermes-watchlist && YOUTUBE_API_KEY=... python3 scripts/fetch_media.py
```

## Deploy the website

Any static host works. For **GitHub Pages**: push this repo, then in
*Settings → Pages* serve from the repo root and visit `/web/`. (The catalog is
committed as JSON, so Pages serves it as a static file — no build step.)

## Project layout

```
data/
  sources.json     # where to look + topic-matching rules  (you edit this)
  catalog.json     # aggregated items the app reads         (fetcher writes this)
scripts/
  fetch_media.py   # YouTube + podcast RSS + website aggregator (stdlib only)
  serve.sh         # convenience local server
web/
  index.html       # the app shell (Up Next / Browse / Library / Stats)
  app.js           # recommender + watched/liked flow + localStorage
  styles.css       # dark UI
```

## Privacy

Your watch history and ratings never leave your browser. There is no analytics,
no account, and no server call other than fetching the static `catalog.json`.

## License

MIT — see [LICENSE](LICENSE).
