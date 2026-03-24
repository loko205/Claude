"""Poisson-based football match prediction model.

Core algorithm:
1. Calculate expected goals (xG) per team from historical attack/defense strength
2. Build Poisson probability matrix for all scorelines
3. Aggregate into 1X2 match probabilities
"""

from scipy.stats import poisson

from src.football.models import LeagueStats, Prediction, TeamStats


def attack_strength(team_goals: int, team_matches: int, league_avg: float) -> float:
    """Team attack strength relative to league average."""
    if team_matches == 0 or league_avg == 0:
        return 1.0
    return (team_goals / team_matches) / league_avg


def defense_weakness(team_conceded: int, team_matches: int, league_avg: float) -> float:
    """Team defense weakness relative to league average. Higher = weaker defense."""
    if team_matches == 0 or league_avg == 0:
        return 1.0
    return (team_conceded / team_matches) / league_avg


def expected_goals(
    home_team: TeamStats,
    away_team: TeamStats,
    league: LeagueStats,
) -> tuple[float, float]:
    """
    Calculate expected goals for both teams.

    home_xg = home_attack * away_defense_weakness * league_avg_home_goals
    away_xg = away_attack * home_defense_weakness * league_avg_away_goals
    """
    avg_h = league.avg_home_goals
    avg_a = league.avg_away_goals

    home_att = attack_strength(home_team.home_goals_scored, home_team.home_matches, avg_h)
    away_def = defense_weakness(away_team.away_goals_conceded, away_team.away_matches, avg_a)

    away_att = attack_strength(away_team.away_goals_scored, away_team.away_matches, avg_a)
    home_def = defense_weakness(home_team.home_goals_conceded, home_team.home_matches, avg_h)

    home_xg = home_att * away_def * avg_h
    away_xg = away_att * home_def * avg_a

    # Clamp to reasonable range
    home_xg = max(0.1, min(home_xg, 5.0))
    away_xg = max(0.1, min(away_xg, 5.0))

    return home_xg, away_xg


def scoreline_probabilities(
    home_xg: float,
    away_xg: float,
    max_goals: int = 7,
) -> dict[tuple[int, int], float]:
    """
    Poisson probability matrix for all scorelines up to max_goals.

    Assumes independence between home and away goals.
    P(home=i, away=j) = poisson(i, home_xg) * poisson(j, away_xg)
    """
    probs: dict[tuple[int, int], float] = {}
    for i in range(max_goals + 1):
        p_home = poisson.pmf(i, home_xg)
        for j in range(max_goals + 1):
            p_away = poisson.pmf(j, away_xg)
            probs[(i, j)] = p_home * p_away
    return probs


def match_probabilities(
    scoreline_probs: dict[tuple[int, int], float],
) -> tuple[float, float, float]:
    """Aggregate scoreline probabilities into (home_win, draw, away_win)."""
    home_win = 0.0
    draw = 0.0
    away_win = 0.0

    for (h, a), prob in scoreline_probs.items():
        if h > a:
            home_win += prob
        elif h == a:
            draw += prob
        else:
            away_win += prob

    # Normalize to account for truncated scoreline matrix
    total = home_win + draw + away_win
    if total > 0:
        home_win /= total
        draw /= total
        away_win /= total

    return home_win, draw, away_win


def over_under_prob(
    scoreline_probs: dict[tuple[int, int], float],
    line: float = 2.5,
) -> tuple[float, float]:
    """P(over), P(under) for a given goal line."""
    over = sum(p for (h, a), p in scoreline_probs.items() if h + a > line)
    under = sum(p for (h, a), p in scoreline_probs.items() if h + a < line)
    return over, under


def predict_match(
    home_team: TeamStats,
    away_team: TeamStats,
    league: LeagueStats,
) -> Prediction:
    """Complete match prediction using Poisson model."""
    home_xg, away_xg = expected_goals(home_team, away_team, league)
    scorelines = scoreline_probabilities(home_xg, away_xg)
    h_prob, d_prob, a_prob = match_probabilities(scorelines)

    return Prediction(
        home_team=home_team.name,
        away_team=away_team.name,
        home_xg=home_xg,
        away_xg=away_xg,
        home_prob=h_prob,
        draw_prob=d_prob,
        away_prob=a_prob,
        scoreline_probs=scorelines,
    )
