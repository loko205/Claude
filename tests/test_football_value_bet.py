"""Tests for value bet detection and Kelly criterion."""

import pytest

from src.football.models import MatchOdds, Prediction, ValueBet
from src.football.odds import odds_to_implied_prob, remove_vig
from src.football.value_bet import find_value_bets, kelly_stake


class TestOddsConversion:
    def test_even_odds(self):
        assert odds_to_implied_prob(2.0) == pytest.approx(0.5)

    def test_heavy_favorite(self):
        assert odds_to_implied_prob(1.2) == pytest.approx(1.0 / 1.2)

    def test_longshot(self):
        assert odds_to_implied_prob(10.0) == pytest.approx(0.1)

    def test_odds_at_one(self):
        assert odds_to_implied_prob(1.0) == 1.0


class TestRemoveVig:
    def test_fair_odds(self):
        # Fair odds: no vig, should stay the same
        h, d, a = remove_vig(2.0, 5.0, 5.0)
        assert h + d + a == pytest.approx(1.0)

    def test_with_vig(self):
        # Typical bookmaker odds with ~5% margin
        h, d, a = remove_vig(1.90, 3.60, 4.20)
        assert h + d + a == pytest.approx(1.0)
        assert h > d  # home still favorite after vig removal
        assert d > a


class TestKellyStake:
    def test_no_edge_returns_zero(self):
        # If model_prob equals implied prob, Kelly = 0
        assert kelly_stake(0.5, 2.0) == 0.0

    def test_positive_edge(self):
        # Model says 60% but odds imply 50% (odds = 2.0)
        stake = kelly_stake(0.6, 2.0, fraction=1.0)
        # f* = (1*0.6 - 0.4) / 1 = 0.2
        assert stake == pytest.approx(0.2)

    def test_quarter_kelly(self):
        stake = kelly_stake(0.6, 2.0, fraction=0.25)
        assert stake == pytest.approx(0.05)

    def test_negative_edge_returns_zero(self):
        # Model says 30% but odds imply 50%
        assert kelly_stake(0.3, 2.0) == 0.0

    def test_capped_at_fraction(self):
        # Even with huge edge, capped at kelly_fraction
        stake = kelly_stake(0.99, 1.5, fraction=0.25)
        assert stake <= 0.25


class TestFindValueBets:
    @pytest.fixture
    def prediction(self) -> Prediction:
        return Prediction(
            home_team="TeamA",
            away_team="TeamB",
            home_xg=2.0,
            away_xg=0.8,
            home_prob=0.65,
            draw_prob=0.20,
            away_prob=0.15,
        )

    def test_finds_value_when_edge_exists(self, prediction):
        # Bookmaker underestimates home win: odds 1.80 -> implied 55.6%
        # Model says 65% -> edge = 9.4%
        odds = [MatchOdds("TeamA", "TeamB", "TestBookie", 1.80, 3.60, 5.00)]
        vbs = find_value_bets(prediction, odds, min_edge_pct=5.0)
        assert len(vbs) >= 1
        home_vb = [v for v in vbs if v.outcome == "1"]
        assert len(home_vb) == 1
        assert home_vb[0].edge_pct > 5.0

    def test_no_value_when_odds_fair(self, prediction):
        # Odds perfectly reflect model -> no value
        odds = [MatchOdds("TeamA", "TeamB", "FairBookie", 1.54, 5.00, 6.67)]
        vbs = find_value_bets(prediction, odds, min_edge_pct=5.0)
        assert len(vbs) == 0

    def test_multiple_bookmakers(self, prediction):
        odds = [
            MatchOdds("TeamA", "TeamB", "Bookie1", 1.80, 3.60, 5.00),
            MatchOdds("TeamA", "TeamB", "Bookie2", 1.90, 3.40, 4.50),
        ]
        vbs = find_value_bets(prediction, odds, min_edge_pct=5.0)
        # Should find value at both bookies for home win
        assert len(vbs) >= 2

    def test_sorted_by_edge(self, prediction):
        odds = [
            MatchOdds("TeamA", "TeamB", "Bookie1", 1.80, 3.60, 5.00),
            MatchOdds("TeamA", "TeamB", "Bookie2", 2.00, 3.40, 4.50),
        ]
        vbs = find_value_bets(prediction, odds, min_edge_pct=5.0)
        if len(vbs) >= 2:
            assert vbs[0].edge_pct >= vbs[1].edge_pct

    def test_kelly_stake_calculated(self, prediction):
        odds = [MatchOdds("TeamA", "TeamB", "TestBookie", 1.80, 3.60, 5.00)]
        vbs = find_value_bets(prediction, odds, min_edge_pct=5.0, kelly_fraction=0.25)
        for vb in vbs:
            assert vb.kelly_stake > 0
            assert vb.kelly_stake <= 0.25
