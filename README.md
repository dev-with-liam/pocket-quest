# Pocket Games

A pocketful of quick, colorful mini-games for iOS, macOS, and visionOS — built entirely in **SwiftUI**. Play a fast round of Wordle, race a reaction timer, climb the 2048 board, or cook up a dish in Yeti's Kitchen, then earn XP, level up your rank, and unlock new Yeti skins along the way.

19 games. One app. No accounts, no ads, no internet required.

<table>
  <tr>
    <td align="center" width="33%"><img src="Screenshots/home.png" alt="Home screen" width="100%"><br><sub><b>Home</b></sub></td>
    <td align="center" width="33%"><img src="Screenshots/games-library.png" alt="Games library" width="100%"><br><sub><b>Games Library</b></sub></td>
    <td align="center" width="33%"><img src="Screenshots/achievements.png" alt="Achievements" width="100%"><br><sub><b>Achievements</b></sub></td>
  </tr>
</table>

---

## Features

- 🎮 **19 mini-games** across four categories — Arcade, Puzzle, Strategy, and Reaction
- 📈 **XP & leveling** — every game you play earns XP toward ranks from *Rookie* to *Quest Legend*
- 🧊 **Yeti Battle Pass** — unlock cosmetic Yeti skins (Cloud, Sunset, Galaxy, Forest, Neon…) as you level up
- 📊 **Persistent stats** — your progress and high scores are saved locally between sessions
- 🎨 **Polished, themed UI** — a consistent brand palette and mascot across every screen
- 📴 **Fully offline** — everything runs on-device

## The Games

### 🕹 Arcade

<table>
  <tr>
    <td align="center" width="25%"><img src="Screenshots/rock-paper-scissors.png" alt="Rock Paper Scissors" width="100%"><br><sub><b>Rock Paper Scissors</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/lucky-toss.png" alt="Lucky Toss" width="100%"><br><sub><b>Lucky Toss</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/bullseye-blitz.png" alt="Bullseye Blitz" width="100%"><br><sub><b>Bullseye Blitz</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/worm-arena.png" alt="Worm Arena" width="100%"><br><sub><b>Worm Arena</b></sub></td>
  </tr>
</table>

### 🧩 Puzzle

<table>
  <tr>
    <td align="center" width="25%"><img src="Screenshots/merge-summit.png" alt="Merge Summit" width="100%"><br><sub><b>Merge Summit (2048)</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/guess-the-word.png" alt="Guess the Word" width="100%"><br><sub><b>Guess the Word</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/hangman.png" alt="Hangman" width="100%"><br><sub><b>Hangman</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/pair-finder.png" alt="Pair Finder" width="100%"><br><sub><b>Pair Finder</b></sub></td>
  </tr>
  <tr>
    <td align="center" width="25%"><img src="Screenshots/secret-number.png" alt="Secret Number" width="100%"><br><sub><b>Secret Number</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/logic-pop.png" alt="Logic Pop" width="100%"><br><sub><b>Logic Pop</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/snack-stack.png" alt="Snack Stack" width="100%"><br><sub><b>Snack Stack</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/yetis-kitchen.png" alt="Yeti's Kitchen" width="100%"><br><sub><b>Yeti's Kitchen</b></sub></td>
  </tr>
</table>

### ♟ Strategy

<table>
  <tr>
    <td align="center" width="25%"><img src="Screenshots/tic-tac-toe.png" alt="Tic-Tac-Toe" width="100%"><br><sub><b>Tic-Tac-Toe</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/stone-strategy.png" alt="Stone Strategy" width="100%"><br><sub><b>Stone Strategy (Nim)</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/pattern-lock.png" alt="Pattern Lock" width="100%"><br><sub><b>Pattern Lock</b></sub></td>
    <td align="center" width="25%"></td>
  </tr>
</table>

### ⚡️ Reaction

<table>
  <tr>
    <td align="center" width="25%"><img src="Screenshots/reaction-time.png" alt="Reaction Time" width="100%"><br><sub><b>Reaction Time</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/clicks-per-second.png" alt="Clicks Per Second" width="100%"><br><sub><b>Clicks Per Second</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/time-freeze.png" alt="Time Freeze" width="100%"><br><sub><b>Time Freeze</b></sub></td>
    <td align="center" width="25%"><img src="Screenshots/hue-match.png" alt="Hue Match" width="100%"><br><sub><b>Hue Match</b></sub></td>
  </tr>
</table>

## Progression

Every game feeds a single XP track. Play anything and you climb ranks from **Rookie** to **Quest Legend**, unlock Yeti skins in the Battle Pass, and rack up achievements.

<table>
  <tr>
    <td align="center" width="50%"><img src="Screenshots/battle-pass.png" alt="Yeti Battle Pass" width="100%"><br><sub><b>Yeti Battle Pass & Settings</b></sub></td>
    <td align="center" width="50%"><img src="Screenshots/player-stats.png" alt="Player level and rank" width="100%"><br><sub><b>Level & Rank</b></sub></td>
  </tr>
</table>

## Requirements

- **Xcode 16** or newer
- **iOS 18.0+** / **macOS 26.5+** / **visionOS 26.5+**
- Swift 5

## Getting Started

Clone the repo and open the project in Xcode:

```bash
git clone https://github.com/dev-with-liam/pocket-games.git
cd pocket-games
open pocket-games.xcodeproj
```

Then in Xcode:

1. Select the **pocket-games** scheme and a run destination (an iPhone simulator, your Mac, or a connected device).
2. Press **▶︎ Run** (`⌘R`).

That's it — the app launches straight into the game hub. Pick a game and play.

## Project Structure

The app follows an **MVVM** architecture:

```
pocket-games/
├── Models/         # Game state & data types (GameOption, board states, moves…)
├── ViewModels/     # Per-game logic and state management
├── Views/          # SwiftUI screens — HomeView is the hub
├── Resources/      # Bundled assets (e.g. the word list)
├── Assets.xcassets # App icon, colors, and the Yeti mascot art
└── pocket_gamesApp.swift  # App entry point
```

Each game is a self-contained trio — a `Model`, a `ViewModel`, and a `View` — so adding a new game means adding a case to `GameOption` and dropping in those three files.

## Contributing

Issues and pull requests are welcome. If you're adding a game, follow the existing Model/ViewModel/View pattern and register it in `GameOption`.

## License

See [LICENSE](LICENSE) if present, or contact the author regarding usage.
