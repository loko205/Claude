"""CLI entry point for football value betting analysis.

Usage:
    # With API keys configured in .env:
    python -m src.football.main

    # Without API keys — uses demo data:
    python -m src.football.main --demo
"""

import argparse
import asyncio
import sys

from rich.console import Console
from rich.table import Table

from src.football.config import FootballConfig
from src.football.data import FootballDataClient, build_league_stats_from_results
from src.football.models import MatchOdds, Prediction
from src.football.odds import OddsClient, create_manual_odds, odds_to_implied_prob, remove_vig
from src.football.poisson import over_under_prob, predict_match
from src.football.value_bet import find_value_bets

console = Console()


# --- Demo data for testing without API keys ---

DEMO_RESULTS: list[tuple[str, str, int, int]] = [
    # Bundesliga-style sample data (simplified)
    ("Bayern München", "Dortmund", 3, 1),
    ("Bayern München", "Leipzig", 2, 0),
    ("Bayern München", "Leverkusen", 2, 2),
    ("Bayern München", "Frankfurt", 4, 1),
    ("Bayern München", "Freiburg", 3, 0),
    ("Bayern München", "Stuttgart", 2, 1),
    ("Bayern München", "Wolfsburg", 5, 1),
    ("Bayern München", "Gladbach", 3, 0),
    ("Bayern München", "Union Berlin", 2, 0),
    ("Dortmund", "Bayern München", 1, 3),
    ("Dortmund", "Leipzig", 3, 2),
    ("Dortmund", "Leverkusen", 1, 1),
    ("Dortmund", "Frankfurt", 2, 0),
    ("Dortmund", "Freiburg", 3, 1),
    ("Dortmund", "Stuttgart", 2, 1),
    ("Dortmund", "Wolfsburg", 3, 0),
    ("Dortmund", "Gladbach", 4, 2),
    ("Dortmund", "Union Berlin", 2, 1),
    ("Leipzig", "Bayern München", 0, 1),
    ("Leipzig", "Dortmund", 2, 1),
    ("Leipzig", "Leverkusen", 2, 2),
    ("Leipzig", "Frankfurt", 3, 1),
    ("Leipzig", "Freiburg", 1, 0),
    ("Leipzig", "Stuttgart", 2, 1),
    ("Leipzig", "Wolfsburg", 2, 0),
    ("Leipzig", "Gladbach", 3, 1),
    ("Leipzig", "Union Berlin", 1, 0),
    ("Leverkusen", "Bayern München", 1, 2),
    ("Leverkusen", "Dortmund", 2, 1),
    ("Leverkusen", "Leipzig", 3, 0),
    ("Leverkusen", "Frankfurt", 2, 1),
    ("Leverkusen", "Freiburg", 3, 1),
    ("Leverkusen", "Stuttgart", 2, 0),
    ("Leverkusen", "Wolfsburg", 4, 1),
    ("Leverkusen", "Gladbach", 2, 0),
    ("Leverkusen", "Union Berlin", 3, 1),
    ("Frankfurt", "Bayern München", 1, 5),
    ("Frankfurt", "Dortmund", 1, 2),
    ("Frankfurt", "Leipzig", 0, 2),
    ("Frankfurt", "Leverkusen", 1, 1),
    ("Frankfurt", "Freiburg", 2, 1),
    ("Frankfurt", "Stuttgart", 1, 1),
    ("Frankfurt", "Wolfsburg", 2, 0),
    ("Frankfurt", "Gladbach", 1, 0),
    ("Frankfurt", "Union Berlin", 2, 1),
    ("Freiburg", "Bayern München", 0, 2),
    ("Freiburg", "Dortmund", 1, 3),
    ("Freiburg", "Leipzig", 1, 1),
    ("Freiburg", "Leverkusen", 0, 2),
    ("Freiburg", "Frankfurt", 2, 1),
    ("Freiburg", "Stuttgart", 1, 0),
    ("Freiburg", "Wolfsburg", 2, 1),
    ("Freiburg", "Gladbach", 1, 0),
    ("Freiburg", "Union Berlin", 2, 0),
    ("Stuttgart", "Bayern München", 1, 3),
    ("Stuttgart", "Dortmund", 0, 1),
    ("Stuttgart", "Leipzig", 1, 2),
    ("Stuttgart", "Leverkusen", 1, 1),
    ("Stuttgart", "Frankfurt", 2, 2),
    ("Stuttgart", "Freiburg", 2, 0),
    ("Stuttgart", "Wolfsburg", 3, 1),
    ("Stuttgart", "Gladbach", 2, 1),
    ("Stuttgart", "Union Berlin", 1, 0),
    ("Wolfsburg", "Bayern München", 0, 3),
    ("Wolfsburg", "Dortmund", 1, 2),
    ("Wolfsburg", "Leipzig", 1, 1),
    ("Wolfsburg", "Leverkusen", 0, 2),
    ("Wolfsburg", "Frankfurt", 1, 1),
    ("Wolfsburg", "Freiburg", 1, 0),
    ("Wolfsburg", "Stuttgart", 2, 1),
    ("Wolfsburg", "Gladbach", 1, 0),
    ("Wolfsburg", "Union Berlin", 2, 1),
    ("Gladbach", "Bayern München", 0, 2),
    ("Gladbach", "Dortmund", 1, 3),
    ("Gladbach", "Leipzig", 0, 1),
    ("Gladbach", "Leverkusen", 1, 3),
    ("Gladbach", "Frankfurt", 2, 2),
    ("Gladbach", "Freiburg", 1, 1),
    ("Gladbach", "Stuttgart", 1, 0),
    ("Gladbach", "Wolfsburg", 2, 1),
    ("Gladbach", "Union Berlin", 1, 1),
    ("Union Berlin", "Bayern München", 0, 3),
    ("Union Berlin", "Dortmund", 0, 1),
    ("Union Berlin", "Leipzig", 1, 2),
    ("Union Berlin", "Leverkusen", 0, 1),
    ("Union Berlin", "Frankfurt", 1, 0),
    ("Union Berlin", "Freiburg", 1, 1),
    ("Union Berlin", "Stuttgart", 0, 0),
    ("Union Berlin", "Wolfsburg", 1, 0),
    ("Union Berlin", "Gladbach", 2, 1),
]

DEMO_UPCOMING = [
    ("Bayern München", "Dortmund"),
    ("Leipzig", "Leverkusen"),
    ("Frankfurt", "Freiburg"),
]

DEMO_ODDS = [
    ("Bayern München", "Dortmund", 1.55, 4.20, 5.80, "Bet365"),
    ("Bayern München", "Dortmund", 1.50, 4.50, 6.00, "Unibet"),
    ("Leipzig", "Leverkusen", 2.40, 3.50, 2.80, "Bet365"),
    ("Leipzig", "Leverkusen", 2.35, 3.40, 2.90, "Unibet"),
    ("Frankfurt", "Freiburg", 2.10, 3.40, 3.50, "Bet365"),
    ("Frankfurt", "Freiburg", 2.15, 3.30, 3.40, "Unibet"),
]


def display_prediction(pred: Prediction) -> None:
    """Display a single match prediction."""
    console.print(f"\n[bold cyan]⚽ {pred.home_team} vs {pred.away_team}[/bold cyan]")
    console.print(f"   Expected Goals: {pred.home_xg:.2f} - {pred.away_xg:.2f}")
    console.print(
        f"   Model: [green]1={pred.home_prob:.1%}[/green]  "
        f"[yellow]X={pred.draw_prob:.1%}[/yellow]  "
        f"[red]2={pred.away_prob:.1%}[/red]"
    )
    # Over/Under 2.5
    o, u = over_under_prob(pred.scoreline_probs, 2.5)
    console.print(f"   Over 2.5: {o:.1%}  |  Under 2.5: {u:.1%}")

    # Most likely scorelines
    top_scores = sorted(pred.scoreline_probs.items(), key=lambda x: x[1], reverse=True)[:5]
    scores_str = "  ".join(f"{h}-{a}: {p:.1%}" for (h, a), p in top_scores)
    console.print(f"   Top Scorelines: {scores_str}")


def display_value_bets(value_bets: list, bankroll: float) -> None:
    """Display value bets in a rich table."""
    if not value_bets:
        console.print("\n[yellow]Keine Value Bets gefunden.[/yellow]")
        return

    table = Table(title="💰 Value Bets", show_header=True, header_style="bold magenta")
    table.add_column("Match", style="cyan")
    table.add_column("Tipp", justify="center")
    table.add_column("Modell %", justify="right", style="green")
    table.add_column("Implied %", justify="right", style="red")
    table.add_column("Quote", justify="right")
    table.add_column("Edge %", justify="right", style="bold green")
    table.add_column("Kelly €", justify="right", style="yellow")
    table.add_column("Bookie", style="dim")

    for vb in value_bets:
        table.add_row(
            f"{vb.home_team} vs {vb.away_team}",
            vb.outcome,
            f"{vb.model_prob:.1%}",
            f"{vb.implied_prob:.1%}",
            f"{vb.odds:.2f}",
            f"+{vb.edge_pct:.1f}%",
            f"€{vb.kelly_stake * bankroll:.2f}",
            vb.bookmaker,
        )

    console.print()
    console.print(table)


def display_odds_comparison(pred: Prediction, odds_list: list[MatchOdds]) -> None:
    """Show side-by-side comparison of model vs bookmaker probabilities."""
    table = Table(title=f"📊 {pred.home_team} vs {pred.away_team} — Odds-Vergleich")
    table.add_column("", style="bold")
    table.add_column("Modell", justify="right", style="green")
    for o in odds_list:
        table.add_column(o.bookmaker, justify="right")

    for label, model_p, get_odds in [
        ("1 (Heim)", pred.home_prob, lambda o: o.home_odds),
        ("X (Remis)", pred.draw_prob, lambda o: o.draw_odds),
        ("2 (Auswärts)", pred.away_prob, lambda o: o.away_odds),
    ]:
        row = [label, f"{model_p:.1%}"]
        for o in odds_list:
            implied = odds_to_implied_prob(get_odds(o))
            fair = remove_vig(o.home_odds, o.draw_odds, o.away_odds)
            fair_p = {"1 (Heim)": fair[0], "X (Remis)": fair[1], "2 (Auswärts)": fair[2]}[label]
            diff = model_p - implied
            color = "green" if diff > 0.03 else ("red" if diff < -0.03 else "white")
            row.append(f"[{color}]{implied:.1%} ({get_odds(o):.2f})[/{color}]")
        table.add_row(*row)

    console.print()
    console.print(table)


async def run_with_api(config: FootballConfig) -> None:
    """Run analysis using live API data."""
    data_client = FootballDataClient(config)
    odds_client = OddsClient(config)

    all_value_bets = []

    for league in config.leagues:
        console.print(f"\n[bold]{'='*60}[/bold]")
        console.print(f"[bold]Liga: {league}[/bold]")

        league_stats = await data_client.build_league_stats(league, config.season)
        if not league_stats.teams:
            console.print(f"[yellow]Keine Daten für {league} Season {config.season}[/yellow]")
            continue

        console.print(f"  Teams: {len(league_stats.teams)} | Spiele: {league_stats.total_matches}")
        console.print(f"  Ø Tore: Heim {league_stats.avg_home_goals:.2f} | Auswärts {league_stats.avg_away_goals:.2f}")

        upcoming = await data_client.get_upcoming(league)
        if not upcoming:
            console.print("[yellow]  Keine kommenden Spiele gefunden.[/yellow]")
            continue

        try:
            odds_list = await odds_client.get_odds(league)
        except ValueError:
            odds_list = []
            console.print("[yellow]  Keine Odds (ODDS_API_KEY fehlt).[/yellow]")

        for match in upcoming[:10]:
            home = match["homeTeam"]["name"]
            away = match["awayTeam"]["name"]

            if home not in league_stats.teams or away not in league_stats.teams:
                continue

            pred = predict_match(league_stats.teams[home], league_stats.teams[away], league_stats)
            display_prediction(pred)

            # Find matching odds
            match_odds = [o for o in odds_list if o.home_team == home and o.away_team == away]
            if match_odds:
                display_odds_comparison(pred, match_odds)
                vbs = find_value_bets(pred, match_odds, config.min_edge_pct, config.kelly_fraction)
                all_value_bets.extend(vbs)

    display_value_bets(all_value_bets, config.bankroll)


def run_demo(config: FootballConfig) -> None:
    """Run analysis with demo data — no API keys needed."""
    console.print("[bold cyan]🏟️  Football Value Betting — Demo Modus[/bold cyan]")
    console.print("[dim]Verwende Beispieldaten (Bundesliga-ähnlich)[/dim]\n")

    league_stats = build_league_stats_from_results("BL1", 2025, DEMO_RESULTS)
    console.print(f"Teams: {len(league_stats.teams)} | Spiele: {league_stats.total_matches}")
    console.print(f"Ø Tore: Heim {league_stats.avg_home_goals:.2f} | Auswärts {league_stats.avg_away_goals:.2f}")

    all_value_bets = []

    for home_name, away_name in DEMO_UPCOMING:
        home_team = league_stats.teams[home_name]
        away_team = league_stats.teams[away_name]

        pred = predict_match(home_team, away_team, league_stats)
        display_prediction(pred)

        # Get demo odds for this match
        match_odds = [
            create_manual_odds(h, a, ho, do, ao, bk)
            for h, a, ho, do, ao, bk in DEMO_ODDS
            if h == home_name and a == away_name
        ]

        if match_odds:
            display_odds_comparison(pred, match_odds)
            vbs = find_value_bets(pred, match_odds, config.min_edge_pct, config.kelly_fraction)
            all_value_bets.extend(vbs)

    display_value_bets(all_value_bets, config.bankroll)

    console.print("\n[dim]─────────────────────────────────────[/dim]")
    console.print("[dim]Für Live-Daten: API-Keys in .env eintragen[/dim]")
    console.print("[dim]  FOOTBALL_DATA_API_KEY=... (football-data.org)[/dim]")
    console.print("[dim]  ODDS_API_KEY=...          (the-odds-api.com)[/dim]")


def main():
    parser = argparse.ArgumentParser(description="Football Value Betting Predictor")
    parser.add_argument("--demo", action="store_true", help="Run with demo data (no API keys needed)")
    args = parser.parse_args()

    config = FootballConfig.from_env()

    if args.demo or (not config.football_data_api_key and not config.odds_api_key):
        run_demo(config)
    else:
        asyncio.run(run_with_api(config))


if __name__ == "__main__":
    main()
