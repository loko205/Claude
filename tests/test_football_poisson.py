"""Tests for the Poisson prediction model."""

import pytest

from src.football.data import build_league_stats_from_results
from src.football.models import LeagueStats, TeamStats
from src.football.poisson import (
    attack_strength,
    defense_weakness,
    expected_goals,
    match_probabilities,
    over_under_prob,
    predict_match,
    scoreline_probabilities,
)


@pytest.fixture
def sample_league() -> LeagueStats:
    """Build a small league from results."""
    results = [
        ("TeamA", "TeamB", 3, 1),
        ("TeamA", "TeamC", 2, 0),
        ("TeamB", "TeamA", 1, 2),
        ("TeamB", "TeamC", 2, 1),
        ("TeamC", "TeamA", 0, 1),
        ("TeamC", "TeamB", 1, 2),
    ]
    return build_league_stats_from_results("TEST", 2025, results)


class TestAttackDefenseStrength:
    def test_average_team_returns_one(self):
        # A team scoring exactly the league average has strength 1.0
        assert attack_strength(15, 10, 1.5) == pytest.approx(1.0)

    def test_strong_attack(self):
        # Team scores 3.0/game vs league avg 1.5 -> strength 2.0
        assert attack_strength(30, 10, 1.5) == pytest.approx(2.0)

    def test_weak_defense(self):
        # Team concedes 2.0/game vs league avg 1.0 -> weakness 2.0
        assert defense_weakness(20, 10, 1.0) == pytest.approx(2.0)

    def test_zero_matches_returns_one(self):
        assert attack_strength(0, 0, 1.5) == 1.0
        assert defense_weakness(0, 0, 1.0) == 1.0


class TestExpectedGoals:
    def test_returns_positive(self, sample_league):
        home = sample_league.teams["TeamA"]
        away = sample_league.teams["TeamB"]
        h_xg, a_xg = expected_goals(home, away, sample_league)
        assert h_xg > 0
        assert a_xg > 0

    def test_strong_home_team_higher_xg(self, sample_league):
        # TeamA is strongest, should have higher xG at home
        home = sample_league.teams["TeamA"]
        away = sample_league.teams["TeamC"]
        h_xg, a_xg = expected_goals(home, away, sample_league)
        assert h_xg > a_xg

    def test_xg_clamped(self):
        # Even extreme values get clamped
        monster = TeamStats(name="Monster", home_goals_scored=100, home_matches=1, home_goals_conceded=0)
        weak = TeamStats(name="Weak", away_goals_scored=0, away_matches=1, away_goals_conceded=100)
        league = LeagueStats(league="T", season=2025, total_matches=10, total_home_goals=15, total_away_goals=10)
        league.teams = {"Monster": monster, "Weak": weak}
        h_xg, a_xg = expected_goals(monster, weak, league)
        assert h_xg <= 5.0
        assert a_xg >= 0.1


class TestScorelineProbabilities:
    def test_probabilities_sum_to_near_one(self):
        probs = scoreline_probabilities(1.5, 1.2, max_goals=7)
        total = sum(probs.values())
        assert total == pytest.approx(1.0, abs=0.01)

    def test_most_likely_scoreline_reasonable(self):
        probs = scoreline_probabilities(1.5, 1.0)
        top = max(probs, key=probs.get)
        # Most likely should be a low-scoring game
        assert top[0] <= 3 and top[1] <= 3


class TestMatchProbabilities:
    def test_probabilities_sum_to_one(self):
        probs = scoreline_probabilities(1.5, 1.2)
        h, d, a = match_probabilities(probs)
        assert h + d + a == pytest.approx(1.0, abs=0.01)

    def test_home_favorite(self):
        # High home xG, low away -> home should be favorite
        probs = scoreline_probabilities(2.5, 0.5)
        h, d, a = match_probabilities(probs)
        assert h > d
        assert h > a

    def test_balanced_match(self):
        probs = scoreline_probabilities(1.3, 1.3)
        h, d, a = match_probabilities(probs)
        # Should be roughly equal home/away, draw lower
        assert abs(h - a) < 0.05


class TestOverUnder:
    def test_high_scoring_game(self):
        probs = scoreline_probabilities(2.5, 2.0)
        over, under = over_under_prob(probs, 2.5)
        assert over > under  # high xG -> over more likely

    def test_low_scoring_game(self):
        probs = scoreline_probabilities(0.5, 0.5)
        over, under = over_under_prob(probs, 2.5)
        assert under > over  # low xG -> under more likely


class TestPredictMatch:
    def test_returns_prediction(self, sample_league):
        home = sample_league.teams["TeamA"]
        away = sample_league.teams["TeamB"]
        pred = predict_match(home, away, sample_league)
        assert pred.home_team == "TeamA"
        assert pred.away_team == "TeamB"
        assert pred.home_prob + pred.draw_prob + pred.away_prob == pytest.approx(1.0, abs=0.01)
        assert pred.home_xg > 0
        assert pred.away_xg > 0
        assert len(pred.scoreline_probs) > 0
