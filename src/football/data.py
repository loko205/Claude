"""Football data client — fetches from football-data.org or uses local sample data."""

import asyncio
from typing import Any

import httpx

from src.football.config import FootballConfig
from src.football.models import LeagueStats, TeamStats

# Rate limit: 10 req/min on free tier
RATE_LIMIT_DELAY = 6.5  # seconds between requests


class FootballDataClient:
    """Async client for football-data.org API."""

    BASE_URL = "https://api.football-data.org/v4"

    def __init__(self, config: FootballConfig):
        self.config = config
        self._headers = {"X-Auth-Token": config.football_data_api_key} if config.football_data_api_key else {}

    async def _get(self, path: str) -> dict[str, Any]:
        """Make an authenticated GET request."""
        if not self.config.football_data_api_key:
            raise ValueError(
                "FOOTBALL_DATA_API_KEY not set. "
                "Get a free key at https://www.football-data.org/client/register"
            )
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{self.BASE_URL}{path}",
                headers=self._headers,
                timeout=15.0,
            )
            resp.raise_for_status()
            await asyncio.sleep(RATE_LIMIT_DELAY)
            return resp.json()

    async def get_matches(self, league: str, season: int) -> list[dict]:
        """Get finished matches for a league/season."""
        data = await self._get(f"/competitions/{league}/matches?season={season}&status=FINISHED")
        return data.get("matches", [])

    async def get_upcoming(self, league: str) -> list[dict]:
        """Get upcoming scheduled matches."""
        data = await self._get(f"/competitions/{league}/matches?status=SCHEDULED")
        return data.get("matches", [])

    async def build_league_stats(self, league: str, season: int) -> LeagueStats:
        """Build league stats from finished match data."""
        matches = await self.get_matches(league, season)
        return self._aggregate_matches(league, season, matches)

    @staticmethod
    def _aggregate_matches(league: str, season: int, matches: list[dict]) -> LeagueStats:
        """Aggregate raw match data into LeagueStats."""
        stats = LeagueStats(league=league, season=season)
        teams: dict[str, TeamStats] = {}

        for m in matches:
            score = m.get("score", {}).get("fullTime", {})
            home_goals = score.get("home")
            away_goals = score.get("away")
            if home_goals is None or away_goals is None:
                continue

            home_name = m["homeTeam"]["name"]
            away_name = m["awayTeam"]["name"]

            if home_name not in teams:
                teams[home_name] = TeamStats(name=home_name)
            if away_name not in teams:
                teams[away_name] = TeamStats(name=away_name)

            ht = teams[home_name]
            at = teams[away_name]

            ht.home_goals_scored += home_goals
            ht.home_goals_conceded += away_goals
            ht.home_matches += 1
            ht.matches_played += 1

            at.away_goals_scored += away_goals
            at.away_goals_conceded += home_goals
            at.away_matches += 1
            at.matches_played += 1

            stats.total_matches += 1
            stats.total_home_goals += home_goals
            stats.total_away_goals += away_goals

        stats.teams = teams
        return stats


def build_league_stats_from_results(
    league: str,
    season: int,
    results: list[tuple[str, str, int, int]],
) -> LeagueStats:
    """
    Build LeagueStats from a simple list of results.
    Each result: (home_team, away_team, home_goals, away_goals)

    Use this when you don't have an API key — feed in manual data.
    """
    stats = LeagueStats(league=league, season=season)
    teams: dict[str, TeamStats] = {}

    for home_name, away_name, home_goals, away_goals in results:
        if home_name not in teams:
            teams[home_name] = TeamStats(name=home_name)
        if away_name not in teams:
            teams[away_name] = TeamStats(name=away_name)

        ht = teams[home_name]
        at = teams[away_name]

        ht.home_goals_scored += home_goals
        ht.home_goals_conceded += away_goals
        ht.home_matches += 1
        ht.matches_played += 1

        at.away_goals_scored += away_goals
        at.away_goals_conceded += home_goals
        at.away_matches += 1
        at.matches_played += 1

        stats.total_matches += 1
        stats.total_home_goals += home_goals
        stats.total_away_goals += away_goals

    stats.teams = teams
    return stats
