from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

OUTPUT_DIR = Path("static/images/crests")

BASE_URL = (
    "https://resources.premierleague.com/"
    "premierleague25/badges-alt/{team_id}.svg"
)

TEAMS = {
    "arsenal": 3,
    "aston-villa": 7,
    "bournemouth": 91,
    "brentford": 94,
    "brighton": 36,
    "chelsea": 8,
    "coventry-city": 9,
    "crystal-palace": 31,
    "everton": 11,
    "fulham": 54,
    "hull-city": 37,
    "ipswich-town": 40,
    "leeds-united": 2,
    "liverpool": 14,
    "manchester-city": 43,
    "manchester-united": 1,
    "newcastle-united": 4,
    "nottingham-forest": 17,
    "sunderland": 56,
    "tottenham-hotspur": 6,
}


def download_crest(name, team_id):
    url = BASE_URL.format(team_id=team_id)
    output_file = OUTPUT_DIR / f"{name}.svg"

    request = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0"
        },
    )

    try:
        with urlopen(request, timeout=15) as response:
            content_type = response.headers.get("Content-Type", "")
            data = response.read()

        # Basic sanity check so we don't accidentally save an HTML error
        # page as an SVG.
        if b"<svg" not in data[:1000].lower():
            print(f"FAILED  {name}: response does not appear to be SVG")
            print(f"        {url}")
            return False

        output_file.write_bytes(data)

        print(f"OK      {name:<20} -> {output_file}")
        return True

    except HTTPError as e:
        print(f"FAILED  {name}: HTTP {e.code}")
        print(f"        {url}")
        return False

    except URLError as e:
        print(f"FAILED  {name}: {e.reason}")
        print(f"        {url}")
        return False


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    successful = 0

    for name, team_id in TEAMS.items():
        if download_crest(name, team_id):
            successful += 1

    print()
    print(f"Downloaded {successful}/{len(TEAMS)} crests.")
    print(f"Location: {OUTPUT_DIR.resolve()}")


if __name__ == "__main__":
    main()