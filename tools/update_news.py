"""Collect short, attributed headlines from official Austrian Joyn show pages."""
from __future__ import annotations

import argparse
import concurrent.futures
from datetime import datetime, timedelta, timezone
from html import unescape
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import sys
from urllib.parse import urljoin, urlparse, parse_qs
from urllib.request import Request, urlopen

HUB = "https://www.joyn.at/bts/serien/forsthaus-rampensau"
CAST = HUB + "/forsthaus-rampensau-diese-reality-stars-wagen-den-kampf-um-den-titel-rampensau2026-166109"
TEAMS = [
    ["Beverly", "Elsa"], ["Susi", "Norbert"], ["Simone Lugner", "Alexander Schneller", "Alex"],
    ["Philisha Conditioner", "Shira"], ["Phillip", "Rafael"], ["Butti", "Sophie"],
    ["Julia", "Ebru"], ["Peter", "Alisa"], ["Lisa", "Geri"], ["Krappi", "Vanessa"], ["Julian", "Tom"],
]
DISTINCTIVE = {"simone lugner", "alexander schneller", "philisha conditioner", "shira", "butti", "krappi"}


def clean(text):
    return " ".join(unescape(text).split())


def official_article(url):
    parsed = urlparse(url)
    return parsed.scheme == "https" and parsed.netloc == "www.joyn.at" and parsed.path.startswith(
        "/bts/serien/forsthaus-rampensau/"
    ) and bool(re.search(r"-\d+/?$", parsed.path))


def image_url(url):
    if url.startswith("/bts/_next/image?"):
        url = parse_qs(urlparse(url).query).get("url", [""])[0]
    parsed = urlparse(url)
    return url if parsed.scheme == "https" and parsed.netloc == "img.joyn.de" else ""


def fetch(url):
    request = Request(url, headers={"User-Agent": "ForsthausFantasy/2.1 (private fan league; headline links only)", "Accept": "text/html"})
    with urlopen(request, timeout=15) as response:
        if urlparse(response.geturl()).netloc != "www.joyn.at":
            raise ValueError("Unexpected source redirect")
        return response.read(5_000_000).decode("utf-8")


class Links(HTMLParser):
    """The hub's current-news lane plus article links from the current cast page."""
    def __init__(self, cast_page=False):
        super().__init__(convert_charrefs=True)
        self.urls = []
        self.cast_page = cast_page

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        attrs = dict(attrs)
        url = urljoin(HUB, attrs.get("href", ""))
        if not official_article(url):
            return
        try:
            tracking = json.loads(attrs.get("data-tracking", "{}"))
        except (ValueError, TypeError):
            tracking = {}
        if self.cast_page or tracking.get("laneLabel") == "Aktuelle News":
            if url not in self.urls and url != CAST:
                self.urls.append(url)


class Article(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title_parts = []
        self.in_title = False
        self.meta = {}

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "h1":
            self.in_title = True
        if tag == "meta":
            self.meta[attrs.get("property", attrs.get("name", ""))] = attrs.get("content", "")

    def handle_endtag(self, tag):
        if tag == "h1":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title_parts.append(data)


def tagged_teams(title):
    lower = title.casefold()
    result = []
    for team_id, names in enumerate(TEAMS):
        matches = [name.casefold() for name in names if re.search(r"(?<!\w)" + re.escape(name.casefold()) + r"(?!\w)", lower)]
        # A single ambiguous first name is not enough to assign a news item to a duo.
        if len(matches) >= 2 or any(name in DISTINCTIVE for name in matches):
            result.append(team_id)
    return result


def read_article(url, now):
    parser = Article()
    parser.feed(fetch(url))
    title = clean(" ".join(parser.title_parts) or parser.meta.get("og:title", ""))
    published = parser.meta.get("article:published_time", "")
    if not title or not published:
        raise ValueError("Missing headline or publication date")
    date = datetime.fromisoformat(published.replace("Z", "+00:00"))
    if date.tzinfo is None:
        raise ValueError("Publication date has no timezone")
    if date < max(datetime(2026, 8, 1, tzinfo=timezone.utc), now - timedelta(days=90)) or date > now:
        return None
    if re.search(r"\b202[0-5]\b", title):
        return None
    words = title.split()
    # Only short headline excerpts, never article bodies or generated summaries.
    excerpt = " ".join(words[:24]) + (" …" if len(words) > 24 else "")
    return {
        "id": re.search(r"-(\d+)/?$", urlparse(url).path).group(1),
        "title": excerpt,
        "titleShortened": len(words) > 24,
        "url": url,
        "publishedAt": date.astimezone(timezone.utc).isoformat().replace("+00:00", "Z"),
        "source": "Joyn / ATV",
        "image": image_url(parser.meta.get("og:image", "")),
        "teamIds": tagged_teams(title),
    }


def collect():
    now = datetime.now(timezone.utc)
    urls = []
    errors = []
    for url, is_cast in [(HUB, False), (CAST, True)]:
        try:
            parser = Links(cast_page=is_cast)
            parser.feed(fetch(url))
            if not parser.urls:
                raise ValueError("Official page contained no recognizable article links")
            urls.extend(item for item in parser.urls if item not in urls)
        except Exception as error:
            errors.append(f"{url}: {error}")
    if not urls:
        raise RuntimeError("No official article links found. Existing news data retained.")
    items = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        pending = {pool.submit(read_article, url, now): url for url in urls[:32]}
        for future in concurrent.futures.as_completed(pending):
            try:
                item = future.result()
                if item:
                    items.append(item)
            except Exception as error:
                errors.append(f"{pending[future]}: {error}")
    if not items:
        raise RuntimeError("No verified current headlines found. Existing news data retained.")
    items.sort(key=lambda item: item["publishedAt"], reverse=True)
    return {"schema": 1, "updatedAt": now.isoformat().replace("+00:00", "Z"), "partial": bool(errors), "sources": [HUB, CAST], "items": items[:20]}, errors


def write_feed(feed, output, embed=None):
    text = json.dumps(feed, ensure_ascii=False, indent=2) + "\n"
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.replace(output)
    if embed:
        html = embed.read_text(encoding="utf-8")
        seed = json.dumps(feed, ensure_ascii=False).replace("<", "\\u003c")
        html, count = re.subn(r'(<script id="news-seed" type="application/json">).*?(</script>)', lambda m: m[1] + seed + m[2], html, flags=re.S)
        if count != 1:
            raise ValueError("News seed placeholder missing")
        embed.write_text(html, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    root = Path(__file__).resolve().parents[1]
    parser.add_argument("--output", type=Path, default=root / "news.json")
    parser.add_argument("--embed", type=Path)
    args = parser.parse_args()
    try:
        feed, errors = collect()
        write_feed(feed, args.output, args.embed)
        print(f"Collected {len(feed['items'])} official headlines; {len(errors)} source errors.")
        for error in errors:
            print(error, file=sys.stderr)
    except Exception as error:
        print(f"News update failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
