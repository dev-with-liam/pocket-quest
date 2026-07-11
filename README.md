# Pocket Games

A pocketful of quick, colorful mini-games for iOS, macOS, and visionOS — built entirely in **SwiftUI**. Play a fast round of Wordle, race a reaction timer, climb the 2048 board, or cook up a dish in Yeti's Kitchen, then earn XP, level up your rank, and unlock new Yeti skins along the way.

19 games. One app. No accounts, no ads, no internet required.

---

## Features

- 🎮 **19 mini-games** across four categories — Arcade, Puzzle, Strategy, and Reaction
- 📈 **XP & leveling** — every game you play earns XP toward ranks from *Rookie* to *Quest Legend*
- 🧊 **Yeti Battle Pass** — unlock cosmetic Yeti skins (Cloud, Sunset, Galaxy, Forest, Neon…) as you level up
- 📊 **Persistent stats** — your progress and high scores are saved locally between sessions
- 🎨 **Polished, themed UI** — a consistent brand palette and mascot across every screen
- 📴 **Fully offline** — everything runs on-device

## The Games

| Category | Games |
|----------|-------|
| **Arcade** | Rock Paper Scissors · Lucky Toss · Bullseye Blitz · Worm Arena |
| **Puzzle** | Merge Summit (2048) · Guess the Word (Wordle) · Hangman · Pair Finder · Secret Number · Logic Pop · Snack Stack · Yeti's Kitchen |
| **Strategy** | Tic-Tac-Toe · Stone Strategy (Nim) · Pattern Lock (Code Breaker) |
| **Reaction** | Reaction Time · Clicks Per Second · Time Freeze · Hue Match |

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
