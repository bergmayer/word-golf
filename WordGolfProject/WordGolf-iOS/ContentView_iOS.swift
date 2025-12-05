//
//  ContentView_iOS.swift
//  WordGolf-iOS
//
//  Main game view for iOS - matching Mac design
//

import SwiftUI
import WordGolfCore

struct ContentView_iOS: View {
    @EnvironmentObject var game: GameModel
    @State private var hint1Revealed: String? = nil
    @State private var hint2Revealed: String? = nil
    @FocusState private var isInputFocused: Bool
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingSolver = false

    // Typewriter colors
    private let typewriterBrown = Color(red: 0.25, green: 0.2, blue: 0.15)
    private let typewriterLightBrown = Color(red: 0.4, green: 0.35, blue: 0.3)
    private let woodBrown = Color(red: 0.55, green: 0.4, blue: 0.25)
    private let woodBorderBrown = Color(red: 0.45, green: 0.3, blue: 0.15)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - vertical index card (fills entire window)
                backgroundView(geometry: geometry)

                VStack(spacing: 0) {
                    // Top section with controls
                    VStack(spacing: 16) {
                        // Header row: gear, title, give up
                        headerRow

                        // Hint buttons row
                        hintButtonsRow

                        // Challenge display (word boxes)
                        challengeView

                        // Input section
                        if !game.gameWon {
                            inputSection
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                    // Word chain area with lined paper look
                    wordChainSection
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .alert("About Word Golf", isPresented: $showingAbout) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Transform one word into another by changing one letter at a time.\n\nVersion 1.0\nCopyright 2025 John Bergmayer\nLicensed under GPL 3.0\n\nhttps://github.com/bergmayer/word-golf")
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingSolver) {
            SolverView_iOS()
                .environmentObject(game)
        }
    }

    // MARK: - Background
    @ViewBuilder
    private func backgroundView(geometry: GeometryProxy) -> some View {
        if let imagePath = Bundle.main.path(forResource: "index_card", ofType: "jpg"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .rotationEffect(.degrees(90))
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                .scaleEffect(1.2)
                .ignoresSafeArea()
        } else {
            Color(red: 0.95, green: 0.93, blue: 0.88)
                .ignoresSafeArea()
        }
    }

    // Ladder brown color
    private let ladderBrown = Color(red: 0.7, green: 0.45, blue: 0.2)

    @State private var showingHelpPopover = false

    // MARK: - Header Row
    private var headerRow: some View {
        ZStack {
            // Title (centered)
            Text("word golf")
                .font(.custom("American Typewriter", size: 38).weight(.semibold).italic())
                .foregroundColor(ladderBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.85))
                .cornerRadius(8)

            // Gear on left, help on right (symmetrical)
            HStack {
                gearMenu
                Spacer()
                helpButton
            }
        }
    }

    // MARK: - Help Button (to the right of title)
    private var helpButton: some View {
        Button {
            showingHelpPopover.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(typewriterBrown)
                .frame(width: 44, height: 44)
        }
        .popover(isPresented: $showingHelpPopover) {
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Play")
                    .font(.custom("American Typewriter", size: 16).bold())
                Text("Transform one word into another by changing one letter at a time. Each intermediate step must be a valid word.")
                    .font(.custom("American Typewriter", size: 14))
                    .foregroundColor(.secondary)

                Text("Example")
                    .font(.custom("American Typewriter", size: 16).bold())
                    .padding(.top, 4)
                Text("HEAD → HEAL → TEAL → TELL → TALL → TAIL")
                    .font(.custom("American Typewriter", size: 14))
                    .foregroundColor(.orange)

                Text("Hints")
                    .font(.custom("American Typewriter", size: 16).bold())
                    .padding(.top, 4)
                Text("Hints reveal words from the shortest solution path—not necessarily the next word in sequence.")
                    .font(.custom("American Typewriter", size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .frame(width: 320)
            .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Gear Menu
    private var gearMenu: some View {
        Menu {
            // Difficulty submenu
            Menu("Difficulty") {
                ForEach(DifficultyLevel.allCases) { level in
                    Button {
                        game.setDifficulty(level)
                        resetHints()
                    } label: {
                        HStack {
                            Text(level.displayName)
                            if game.difficulty == level {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                game.newChallenge()
                resetHints()
            } label: {
                Label("New Game", systemImage: "plus.circle")
            }

            Button {
                game.flipDirection()
            } label: {
                Label("Flip Direction", systemImage: "arrow.left.arrow.right")
            }
            .disabled(!game.canFlip)

            Button {
                game.giveUp()
                showingSolver = true
            } label: {
                Label("Solver (ends game)", systemImage: "wand.and.stars")
            }

            Divider()

            Button(role: .destructive) {
                game.giveUp()
            } label: {
                Label("Give Up", systemImage: "flag")
            }
            .disabled(game.gameWon)

            Divider()

            Button {
                showingHelp = true
            } label: {
                Label("How to Play", systemImage: "questionmark.circle")
            }

            Button {
                showingAbout = true
            } label: {
                Label("About Word Golf", systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24))
                .foregroundColor(typewriterBrown)
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Undo Button
    private var undoButton: some View {
        Button {
            game.undo()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(typewriterBrown)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(typewriterLightBrown.opacity(0.5), lineWidth: 1)
                )
        }
        .disabled(!game.canUndo)
        .opacity(game.canUndo ? 1.0 : 0.4)
    }

    // MARK: - Give Up Button (stamp style)
    private var giveUpButton: some View {
        Button {
            game.giveUp()
        } label: {
            Text("Give Up")
                .font(.custom("American Typewriter", size: 16))
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.2))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.6, green: 0.2, blue: 0.2), style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                        .padding(2)
                )
        }
    }

    // MARK: - New Game Button
    private var newGameButton: some View {
        Button {
            game.newChallenge()
            resetHints()
        } label: {
            Text("New Game")
                .font(.custom("American Typewriter", size: 16).bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(typewriterBrown)
                .cornerRadius(6)
        }
    }

    // MARK: - Hint Buttons Row (with Give Up)
    private var hintButtonsRow: some View {
        HStack(spacing: 12) {
            hintButton(revealed: hint1Revealed, action: {
                game.getHint()
                if let hint = game.hints.last {
                    hint1Revealed = hint
                }
            })

            hintButton(revealed: hint2Revealed, action: {
                game.getHint()
                if let hint = game.hints.last {
                    hint2Revealed = hint
                }
            })

            Spacer()

            // Undo button (only when game not won)
            if !game.gameWon {
                undoButton
            }

            // Give Up / New Game button
            if !game.gameWon {
                giveUpButton
            } else {
                newGameButton
            }
        }
    }

    private func hintButton(revealed: String?, action: @escaping () -> Void) -> some View {
        Group {
            if let hint = revealed {
                Text(hint.uppercased())
                    .font(.custom("American Typewriter", size: 18).bold())
                    .foregroundColor(.orange)
                    .frame(width: 80, height: 40)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            } else {
                Button(action: action) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(typewriterBrown)
                        .frame(width: 80, height: 40)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(typewriterLightBrown.opacity(0.5), lineWidth: 1)
                        )
                }
                .disabled(!game.canGetHint)
                .opacity(game.canGetHint ? 1.0 : 0.4)
            }
        }
    }

    // MARK: - Challenge View (wood-style word boxes)
    private var challengeView: some View {
        HStack(spacing: 12) {
            woodWordBox(game.currentWord, isTarget: false)

            // Arrow
            Text("»")
                .font(.custom("American Typewriter", size: 24).bold())
                .foregroundColor(woodBrown)

            woodWordBox(game.targetWord, isTarget: true)
        }
    }

    private func woodWordBox(_ word: String, isTarget: Bool) -> some View {
        Text(word)
            .font(.custom("American Typewriter", size: 22).bold())
            .foregroundColor(.white)
            .frame(minWidth: 70)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.45, blue: 0.3),
                                Color(red: 0.5, green: 0.35, blue: 0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(woodBorderBrown, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 2)
    }

    // MARK: - Input Section
    private var inputSection: some View {
        HStack(spacing: 8) {
            // Text field with rounded border
            HStack {
                TextField("Enter word", text: $game.currentInput)
                    .font(.custom("American Typewriter", size: 20))
                    .foregroundColor(typewriterBrown)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isInputFocused)
                    .onSubmit {
                        game.submitWord(game.currentInput)
                    }
                    .onChange(of: game.currentInput) { _, newValue in
                        if newValue.count > 4 {
                            game.currentInput = String(newValue.prefix(4))
                        }
                        game.currentInput = game.currentInput.lowercased()
                    }

                // Arrow button inside the field
                Button {
                    game.submitWord(game.currentInput)
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(typewriterBrown)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(typewriterLightBrown.opacity(0.5), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Word Chain Section (vertical ladder)
    private var wordChainSection: some View {
        VStack(spacing: 12) {
            // Goal/Status banner (above ladder)
            goalStatusBanner

            // Word ladder content - show optimal path if gave up
            ScrollView {
                WordLadderView(
                    wordChain: game.gaveUp ? game.optimalPath : game.wordChain,
                    targetWord: game.targetWord,
                    isComplete: game.gameWon,
                    gaveUp: game.gaveUp
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, 12)
    }

    // MARK: - Goal/Status Banner
    private var goalStatusBanner: some View {
        HStack {
            Spacer()
            Group {
                if game.gameWon {
                    if game.gaveUp {
                        Text("Solution: \(game.optimalGuessCount) step\(game.optimalGuessCount != 1 ? "s" : "")")
                            .foregroundColor(.orange)
                    } else {
                        Text("Solved in \(game.userGuessCount) step\(game.userGuessCount != 1 ? "s" : "")!")
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.3))
                    }
                } else if !game.statusMessage.isEmpty {
                    Text(game.statusMessage)
                        .foregroundColor(.red)
                } else {
                    Text("Goal: \(game.optimalGuessCount) step\(game.optimalGuessCount != 1 ? "s" : "")")
                        .foregroundColor(typewriterLightBrown)
                }
            }
            .font(.custom("American Typewriter", size: 18).weight(.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
            Spacer()
        }
    }

    private func linedPaperBackground(height: CGFloat) -> some View {
        Canvas { context, size in
            // Draw horizontal lines (subtle blue, matching notebook paper)
            let lineSpacing: CGFloat = 32
            let startY: CGFloat = 24

            var y = startY
            while y < size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: 20, y: y))
                    p.addLine(to: CGPoint(x: size.width - 20, y: y))
                }
                context.stroke(path, with: .color(Color(red: 0.6, green: 0.75, blue: 0.85).opacity(0.4)), lineWidth: 0.5)
                y += lineSpacing
            }

            // Draw left margin line (subtle red/pink)
            let marginPath = Path { p in
                p.move(to: CGPoint(x: 56, y: 0))
                p.addLine(to: CGPoint(x: 56, y: size.height))
            }
            context.stroke(marginPath, with: .color(Color(red: 0.85, green: 0.6, blue: 0.6).opacity(0.4)), lineWidth: 0.5)
        }
    }

    private func resetHints() {
        hint1Revealed = nil
        hint2Revealed = nil
    }
}

// MARK: - Word Ladder View (vertical accordion style)
struct WordLadderView: View {
    let wordChain: [String]
    let targetWord: String
    let isComplete: Bool
    let gaveUp: Bool

    private let ladderColor = Color(red: 0.7, green: 0.45, blue: 0.2)
    private let typewriterBrown = Color(red: 0.25, green: 0.2, blue: 0.15)
    private let fontSize: CGFloat = 32

    var body: some View {
        let displayWords = buildDisplayWords()

        VStack(spacing: 0) {
            ForEach(Array(displayWords.enumerated()), id: \.offset) { index, wordInfo in
                // Show dotted line above target word until game is complete
                // If gave up, solution is shown complete - no dotted lines
                let showDottedTop = wordInfo.isTarget && !isComplete && !gaveUp

                LadderRungView(
                    word: wordInfo.word,
                    isFirst: index == 0,
                    isLast: index == displayWords.count - 1,
                    isTarget: wordInfo.isTarget,
                    isPlaceholder: wordInfo.isPlaceholder && !gaveUp,
                    useDottedTop: showDottedTop,
                    useDottedBottom: wordInfo.isPlaceholder && !gaveUp,
                    ladderColor: ladderColor,
                    typewriterBrown: typewriterBrown,
                    fontSize: fontSize
                )
            }
        }
    }

    private func buildDisplayWords() -> [WordInfo] {
        var words: [WordInfo] = []

        // If gave up, wordChain is the optimal path - show all words
        // Otherwise, show user's progress
        for word in wordChain {
            let isTargetWord = word.lowercased() == targetWord.lowercased()
            let isPlaceholder = false // All words in chain are real
            words.append(WordInfo(word: word, isTarget: isTargetWord, isPlaceholder: isPlaceholder))
        }

        // Add target at bottom if not yet reached and not gave up
        let reachedTarget = wordChain.last?.lowercased() == targetWord.lowercased()
        if !reachedTarget && !isComplete && !gaveUp {
            words.append(WordInfo(word: targetWord, isTarget: true, isPlaceholder: true))
        }

        return words
    }
}

struct WordInfo {
    let word: String
    let isTarget: Bool
    let isPlaceholder: Bool
}

struct LadderRungView: View {
    let word: String
    let isFirst: Bool
    let isLast: Bool
    let isTarget: Bool
    let isPlaceholder: Bool
    let useDottedTop: Bool
    let useDottedBottom: Bool
    let ladderColor: Color
    let typewriterBrown: Color
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            // Left rail
            Rectangle()
                .fill(ladderColor)
                .frame(width: 4)

            // Word rung
            VStack(spacing: 0) {
                // Top border (not for first item)
                if !isFirst {
                    if useDottedTop {
                        // Dotted line before target
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                            .foregroundColor(ladderColor)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(ladderColor)
                            .frame(height: 3)
                    }
                }

                // Word content
                Text(word)
                    .font(.custom("American Typewriter", size: fontSize).weight(.medium))
                    .foregroundColor(isPlaceholder ? ladderColor.opacity(0.7) : typewriterBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(isPlaceholder ? 0.5 : 0.8))

                // Bottom border (only for last item)
                if isLast {
                    if useDottedBottom {
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                            .foregroundColor(ladderColor)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(ladderColor)
                            .frame(height: 3)
                    }
                }
            }

            // Right rail
            Rectangle()
                .fill(ladderColor)
                .frame(width: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// Helper shape for dotted lines
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Help View
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    private let typewriterBrown = Color(red: 0.25, green: 0.2, blue: 0.15)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("How to Play")
                            .font(.custom("American Typewriter", size: 24).bold())
                            .foregroundColor(typewriterBrown)

                        Text("Word Golf is a word puzzle game in which you transform one word into another by changing a single letter at a time. Each intermediate step must form a valid English word, and the goal is to complete the transformation in as few moves as possible.")
                            .font(.custom("American Typewriter", size: 15))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. You are given a starting word and a target word")
                            Text("2. Change exactly one letter at a time to form a new valid word")
                            Text("3. Continue until you reach the target word")
                            Text("4. The fewer steps you use, the better your score")
                        }
                        .font(.custom("American Typewriter", size: 14))
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    Group {
                        Text("Example Puzzles")
                            .font(.custom("American Typewriter", size: 20).bold())
                            .foregroundColor(typewriterBrown)

                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HEAD → TAIL (4 steps)")
                                    .font(.custom("American Typewriter", size: 14).bold())
                                Text("HEAD → HEAL → TEAL → TELL → TALL → TAIL")
                                    .font(.custom("American Typewriter", size: 13))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("LOVE → HATE (4 steps)")
                                    .font(.custom("American Typewriter", size: 14).bold())
                                Text("LOVE → LODE → CODE → CADE → CATE → HATE")
                                    .font(.custom("American Typewriter", size: 13))
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("COLD → WARM (4 steps)")
                                    .font(.custom("American Typewriter", size: 14).bold())
                                Text("COLD → COLE → CORE → WORE → WORM → WARM")
                                    .font(.custom("American Typewriter", size: 13))
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    Divider()

                    Group {
                        Text("History")
                            .font(.custom("American Typewriter", size: 20).bold())
                            .foregroundColor(typewriterBrown)

                        Text("The name \"word golf\" comes from Vladimir Nabokov's 1962 novel Pale Fire. Nabokov has the narrator Charles Kinbote describe the game as a pastime of the poet John Shade:")
                            .font(.custom("American Typewriter", size: 14))

                        Text("\"Some of my records are: hate—love in three, lass—male in four, and live—dead in five (with 'lend' in the middle).\"")
                            .font(.custom("American Typewriter", size: 13))
                            .italic()
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)

                        Text("While this game was inspired by Nabokov, the puzzle itself was invented by Lewis Carroll on Christmas Day, 1877. Carroll originally called the game \"Word-links\" and first published it as \"Doublets\" in Vanity Fair magazine on March 29, 1879.")
                            .font(.custom("American Typewriter", size: 14))

                        Text("Donald Knuth later applied computer analysis to five-letter word ladders, noting that some words—like \"aloof\"—have no neighbors and cannot be connected to any other word. Fittingly, he observed, \"aloof\" is itself aloof.")
                            .font(.custom("American Typewriter", size: 14))
                    }

                    Divider()

                    Group {
                        Text("Word List")
                            .font(.custom("American Typewriter", size: 20).bold())
                            .foregroundColor(typewriterBrown)

                        Text("Word Golf uses a list of 956 most common 4-letter English words (including plurals, e.g., lids), with inappropriate words and proper nouns removed.")
                            .font(.custom("American Typewriter", size: 14))
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.95, green: 0.93, blue: 0.88))
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Solver View for iOS
struct SolverView_iOS: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var game: GameModel
    @State private var startWord: String = ""
    @State private var endWord: String = ""
    @State private var solutionPath: [String] = []
    @State private var errorMessage: String = ""
    @State private var isSearching = false

    private let typewriterBrown = Color(red: 0.25, green: 0.2, blue: 0.15)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Input fields
                HStack(spacing: 12) {
                    TextField("Start", text: $startWord)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(width: 100)
                        .onChange(of: startWord) { _, newValue in
                            startWord = String(newValue.prefix(4)).lowercased()
                        }

                    Text("→")
                        .font(.custom("American Typewriter", size: 20))
                        .foregroundColor(typewriterBrown)

                    TextField("End", text: $endWord)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(width: 100)
                        .onChange(of: endWord) { _, newValue in
                            endWord = String(newValue.prefix(4)).lowercased()
                        }

                    Button("Solve") {
                        solve()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(startWord.count != 4 || endWord.count != 4 || isSearching)
                }
                .padding()

                // Results
                if isSearching {
                    ProgressView("Searching...")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.custom("American Typewriter", size: 14))
                        .foregroundColor(.red)
                        .padding()
                } else if !solutionPath.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Solution (\(solutionPath.count - 1) steps):")
                            .font(.custom("American Typewriter", size: 16).bold())
                            .foregroundColor(typewriterBrown)

                        Text(solutionPath.joined(separator: " → "))
                            .font(.custom("American Typewriter", size: 14))
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                    }
                    .padding()
                }

                Spacer()

                // Use current game button
                Button("Use Current Game Words") {
                    startWord = game.wordChain.first ?? ""
                    endWord = game.targetWord
                }
                .font(.custom("American Typewriter", size: 14))
                .padding(.bottom)
            }
            .background(Color(red: 0.95, green: 0.93, blue: 0.88))
            .navigationTitle("Solver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func solve() {
        guard startWord.count == 4, endWord.count == 4 else { return }

        isSearching = true
        errorMessage = ""
        solutionPath = []

        DispatchQueue.global(qos: .userInitiated).async {
            if let path = game.findShortestPath(from: startWord, to: endWord) {
                DispatchQueue.main.async {
                    solutionPath = path
                    isSearching = false
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage = "No path found between \(startWord) and \(endWord)"
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    ContentView_iOS()
        .environmentObject(GameModel())
}
