"""Value bet detection — compare model probabilities to bookmaker odds."""

from src.football.models import MatchOdds, Prediction, ValueBet
from src.football.odds import odds_to_implied_prob


def kelly_stake(model_prob: float, decimal_odds: float, fraction: float = 0.25) -> float:
    """
    Kelly criterion for optimal stake sizing.

    f* = (b*p - q) / b
    where b = odds - 1, p = model probability, q = 1 - p

    Returns fraction of bankroll to bet. Clamped to [0, fraction].
    """
    if not (0.0 <= model_prob <= 1.0):
        return 0.0
    b = decimal_odds - 1.0
    if b <= 0:
        return 0.0
    p = model_prob
    q = 1.0 - p
    f = (b * p - q) / b
    return max(0.0, min(f * fraction, fraction))


def find_value_bets(
    prediction: Prediction,
    odds_list: list[MatchOdds],
    min_edge_pct: float = 5.0,
    kelly_fraction: float = 0.25,
) -> list[ValueBet]:
    """
    Find value bets by comparing model predictions to bookmaker odds.

    A value bet exists when:
        model_probability > implied_probability + min_edge
    """
    value_bets: list[ValueBet] = []

    outcomes = [
        ("1", prediction.home_prob),
        ("X", prediction.draw_prob),
        ("2", prediction.away_prob),
    ]

    for odds in odds_list:
        odds_map = {
            "1": odds.home_odds,
            "X": odds.draw_odds,
            "2": odds.away_odds,
        }

        for outcome, model_prob in outcomes:
            decimal_odds = odds_map[outcome]
            implied = odds_to_implied_prob(decimal_odds)
            edge = (model_prob - implied) * 100

            if edge >= min_edge_pct:
                stake = kelly_stake(model_prob, decimal_odds, kelly_fraction)
                value_bets.append(ValueBet(
                    home_team=prediction.home_team,
                    away_team=prediction.away_team,
                    outcome=outcome,
                    model_prob=model_prob,
                    implied_prob=implied,
                    odds=decimal_odds,
                    edge_pct=edge,
                    kelly_stake=stake,
                    bookmaker=odds.bookmaker,
                ))

    # Sort by edge descending
    value_bets.sort(key=lambda vb: vb.edge_pct, reverse=True)
    return value_bets
