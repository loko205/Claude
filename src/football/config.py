"""Football betting configuration."""

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

for env_path in [Path(".env"), Path("config/.env")]:
    if env_path.exists():
        load_dotenv(env_path)
        break


# Mapping: football-data.org code -> the-odds-api sport key
LEAGUE_ODDS_MAP: dict[str, str] = {
    "PL": "soccer_epl",
    "BL1": "soccer_germany_bundesliga",
    "SA": "soccer_italy_serie_a",
    "PD": "soccer_spain_la_liga",
    "FL1": "soccer_france_ligue_one",
}


@dataclass
class FootballConfig:
    football_data_api_key: str = ""
    odds_api_key: str = ""
    leagues: list[str] = field(default_factory=lambda: ["PL", "BL1", "SA", "PD", "FL1"])
    min_edge_pct: float = 5.0  # minimum edge to flag as value bet
    kelly_fraction: float = 0.25  # quarter-Kelly (conservative)
    bankroll: float = 100.0
    season: int = 2025  # current season (start year)

    @classmethod
    def from_env(cls) -> "FootballConfig":
        leagues_str = os.getenv("FOOTBALL_LEAGUES", "PL,BL1,SA,PD,FL1")
        return cls(
            football_data_api_key=os.getenv("FOOTBALL_DATA_API_KEY", ""),
            odds_api_key=os.getenv("ODDS_API_KEY", ""),
            leagues=[l.strip() for l in leagues_str.split(",")],
            min_edge_pct=float(os.getenv("FOOTBALL_MIN_EDGE", "5.0")),
            kelly_fraction=float(os.getenv("FOOTBALL_KELLY_FRACTION", "0.25")),
            bankroll=float(os.getenv("FOOTBALL_BANKROLL", "100.0")),
            season=int(os.getenv("FOOTBALL_SEASON", "2025")),
        )
