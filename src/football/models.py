"""Data models for football prediction."""

from dataclasses import dataclass, field


@dataclass
class TeamStats:
    """Aggregated team statistics for a season."""
    name: str
    matches_played: int = 0
    home_goals_scored: int = 0
    home_goals_conceded: int = 0
    away_goals_scored: int = 0
    away_goals_conceded: int = 0
    home_matches: int = 0
    away_matches: int = 0

    @property
    def total_goals_scored(self) -> int:
        return self.home_goals_scored + self.away_goals_scored

    @property
    def total_goals_conceded(self) -> int:
        return self.home_goals_conceded + self.away_goals_conceded


@dataclass
class LeagueStats:
    """League-wide averages and per-team stats."""
    league: str
    season: int
    teams: dict[str, TeamStats] = field(default_factory=dict)
    total_matches: int = 0
    total_home_goals: int = 0
    total_away_goals: int = 0

    @property
    def avg_home_goals(self) -> float:
        """Average home goals per match across the league."""
        return self.total_home_goals / self.total_matches if self.total_matches else 0.0

    @property
    def avg_away_goals(self) -> float:
        """Average away goals per match across the league."""
        return self.total_away_goals / self.total_matches if self.total_matches else 0.0


@dataclass
class Prediction:
    """Model prediction for a match."""
    home_team: str
    away_team: str
    home_xg: float
    away_xg: float
    home_prob: float
    draw_prob: float
    away_prob: float
    scoreline_probs: dict[tuple[int, int], float] = field(default_factory=dict)


@dataclass
class MatchOdds:
    """Bookmaker odds for a match."""
    home_team: str
    away_team: str
    bookmaker: str
    home_odds: float
    draw_odds: float
    away_odds: float


@dataclass
class ValueBet:
    """A detected value bet."""
    home_team: str
    away_team: str
    outcome: str  # "1" (home), "X" (draw), "2" (away)
    model_prob: float
    implied_prob: float
    odds: float
    edge_pct: float  # (model_prob - implied_prob) * 100
    kelly_stake: float  # recommended stake as fraction of bankroll
    bookmaker: str
