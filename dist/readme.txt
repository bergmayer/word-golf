# WORD GOLF

A word puzzle game where you transform one word into another by changing
one letter at a time. Available for macOS and iOS.

Copyright 2025 John Bergmayer
Licensed under GPL 3.0
https://github.com/bergmayer/word-golf


## HOW TO PLAY

Transform the start word into the target word by:
1. Changing exactly one letter at a time
2. Each intermediate word must be a valid English word
3. Try to match or beat the optimal solution length

Example: HEAD -> HEAL -> TEAL -> TELL -> TALL -> TAIL

The "Goal" shown is the shortest possible path. Can you match it?


## FEATURES

- Smart Hints: Get up to 2 hints from the optimal solution path
- Flip Direction: Swap start and target words before making moves
- Undo Support: Take back your last guess
- Solver: Find the shortest path between any two words
- Difficulty Settings: Choose puzzles from 3 to 7+ steps
- Custom Word Lists: Load your own word list files (Mac only)


## KEYBOARD SHORTCUTS (Mac)

Cmd+N        New Game
Cmd+Z        Undo Last Word
Cmd+F        Flip Direction
Cmd+Shift+S  Open Solver
Cmd+Shift+G  Give Up
Cmd+O        Load Custom Word List
Return       Submit word


## RUNNING THE UNSIGNED MAC APP

This app is unsigned. macOS will initially block it from running.
Follow one of these methods to open it:

### Method 1: Right-Click (Easiest)
1. Copy WordGolf.app to your Applications folder (or anywhere)
2. RIGHT-CLICK (or Control-click) on WordGolf.app
3. Select "Open" from the context menu
4. Click "Open" in the warning dialog
5. The app will now run, and macOS will remember your choice

### Method 2: System Settings
1. Try to open WordGolf.app normally (it will be blocked)
2. Open System Settings > Privacy & Security
3. Scroll to Security section
4. Click "Open Anyway" next to the WordGolf message
5. Enter your password if prompted

### Method 3: Terminal (Advanced)
Run this command to remove the quarantine attribute:

    xattr -cr /path/to/WordGolf.app

Example:
    xattr -cr /Applications/WordGolf.app

Then double-click the app normally.

### Troubleshooting
- Requires macOS 14.0 (Sonoma) or later
- If other methods fail, try the Terminal method
- Check System Settings > Privacy & Security for blocked messages


## BUILDING FROM SOURCE

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- XcodeGen (install with: brew install xcodegen)

### Build Mac App
    cd /path/to/word_golf
    ./build-mac.sh

The script will generate the Xcode project, build the app, and launch it.

### Build iOS App (Simulator)
    cd /path/to/word_golf
    ./build-ios.sh

The script will build and install the app in the iPhone simulator.

To specify a different simulator:
    ./build-ios.sh "iPhone 15"

### Manual Build
    xcodegen generate
    xcodebuild -scheme WordGolf -configuration Release build

The built app will be in:
    ~/Library/Developer/Xcode/DerivedData/WordGolf-*/Build/Products/Release/


## ABOUT THE WORD LIST

The app includes 2,449 four-letter English words.

- Connected words: 2,437 (99.5%)
- Island words: 12 words with no neighbors (unreachable)
- Shortest puzzles: 1 step (direct neighbors like HEAD -> HEAL)
- Longest possible: 16 steps (involves the "zz" cluster: buzz, fuzz, jazz)

Difficulty distribution on "Unlimited":
- 1-3 steps: ~25% (Easy)
- 4-5 steps: ~35% (Medium)
- 6-7 steps: ~20% (Challenging)
- 8-10 steps: ~15% (Hard)
- 11-16 steps: ~5% (Expert)


## HISTORY OF WORD GOLF

Word Golf is a word puzzle where you transform one word into another by
changing a single letter at a time. Each step must form a valid word.

### The Name "Word Golf"

The name comes from Vladimir Nabokov's 1962 novel "Pale Fire." The narrator
Charles Kinbote describes the game as a pastime of the poet John Shade:

    "Some of my records are: hate-love in three, lass-male in four,
    and live-dead in five (with 'lend' in the middle)."

### Lewis Carroll's Doublets

The puzzle was invented by Lewis Carroll (Charles Dodgson) on Christmas Day,
1877. Carroll called it "Word-links" and first published it as "Doublets" in
Vanity Fair magazine on March 29, 1879.

Carroll's classic challenge: Transform HEAD into TAIL
    HEAD -> HEAL -> TEAL -> TELL -> TALL -> TAIL

The puzzle became popular in Victorian England under many names: Doublets,
word-links, laddergrams, paragrams, and Stepword.

Donald Knuth later analyzed five-letter word ladders, noting that some words
like "aloof" have no neighbors. As he observed, "aloof" is itself aloof.

More info: https://en.wikipedia.org/wiki/Word_ladder


## PROJECT STRUCTURE

    word_golf/
    ├── readme.txt              # This file
    ├── build-mac.sh            # Mac build script
    ├── build-ios.sh            # iOS build script
    ├── project.yml             # XcodeGen project definition
    ├── icon.jpg                # App icon source
    ├── index_card.jpg          # Background image
    ├── Packages/
    │   └── WordGolfCore/       # Shared game logic
    └── WordGolfProject/
        ├── WordGolf/           # Mac app source
        └── WordGolf-iOS/       # iOS app source


## LICENSE

This software is licensed under the GNU General Public License v3.0.
See the LICENSE file for details.
