"""Odds fetching from the-odds-api.com and probability conversion."""

import httpx

from src.football.config import LEAGUE_ODDS_MAP, FootballConfig
from src.football.models import MatchOdds

RATE_LIMIT_DELAY = 1.0


def odds_to_implied_prob(decimal_odds: float) -> float:
    """Convert decimal odds to implied probability."""
    if decimal_odds <= 1.0:
        return 1.0
    return 1.0 / decimal_odds


def remove_vig(home_odds: float, draw_odds: float, away_odds: float) -> tuple[float, float, float]:
    """Remove bookmaker margin, normalize implied probs to sum to 1.0."""
    raw_h = 1.0 / home_odds
    raw_d = 1.0 / draw_odds
    raw_a = 1.0 / away_odds
    total = raw_h + raw_d + raw_a
    return raw_h / total, raw_d / total, raw_a / total


class OddsClient:
    """Async client for the-odds-api.com."""

    BASE_URL = "https://api.the-odds-api.com/v4"

    def __init__(self, config: FootballConfig):
        self.config = config

    async def get_odds(self, league: str) -> list[MatchOdds]:
        """Fetch current h2h odds for a league."""
        if not self.config.odds_api_key:
            raise ValueError(
                "ODDS_API_KEY not set. "
                "Get a free key at https://the-odds-api.com/#get-access"
            )

        sport = LEAGUE_ODDS_MAP.get(league)
        if not sport:
            return []

        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.BASE_URL}/sports/{sport}/odds",
                params={
                    "apiKey": self.config.odds_api_key,
                    "regions": "eu",
                    "markets": "h2h",
                    "oddsFormat": "decimal",
                },
                timeout=15.0,
            )
            resp.raise_for_status()
            await asyncio.sleep(RATE_LIMIT_DELAY)
            return self._parse_odds(resp.json())

    @staticmethod
    def _parse_odds(data: list[dict]) -> list[MatchOdds]:
        """Parse API response into MatchOdds objects."""
        result: list[MatchOdds] = []
        for event in data:
            home = event.get("home_team", "")
            away = event.get("away_team", "")
            for bm in event.get("bookmakers", []):
                for market in bm.get("markets", []):
                    if market.get("key") != "h2h":
                        continue
                    outcomes = {o["name"]: o["price"] for o in market.get("outcomes", [])}
                    if home in outcomes and away in outcomes and "Draw" in outcomes:
                        result.append(MatchOdds(
                            home_team=home,
                            away_team=away,
                            bookmaker=bm["title"],
                            home_odds=outcomes[home],
                            draw_odds=outcomes["Draw"],
                            away_odds=outcomes[away],
                        ))
        return result


def create_manual_odds(
    home_team: str,
    away_team: str,
    home_odds: float,
    draw_odds: float,
    away_odds: float,
    bookmaker: str = "Manual",
) -> MatchOdds:
    """Create MatchOdds manually — use when no API key available."""
    return MatchOdds(
        home_team=home_team,
        away_team=away_team,
        bookmaker=bookmaker,
        home_odds=home_odds,
        draw_odds=draw_odds,
        away_odds=away_odds,
    )
