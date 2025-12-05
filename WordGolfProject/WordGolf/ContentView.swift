//
//  ContentView.swift
//  WordGolf
//
//  Main game view following macOS Human Interface Guidelines
//

import SwiftUI
import WordGolfCore

struct ContentView: View {
    @EnvironmentObject var game: GameModel
    @State private var showingFileImporter = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.openWindow) private var openWindow
    @State private var hint1Revealed: String? = nil
    @State private var hint2Revealed: String? = nil
    @State private var showingExamplePopover = false

    var body: some View {
        ZStack {
            // Background image
            if let imagePath = Bundle.main.path(forResource: "index_card", ofType: "jpg"),
               let backgroundImage = NSImage(contentsOfFile: imagePath) {
                Image(nsImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }

            // Fixed layout with three zones: top content, scrollable word chain, bottom buttons
            VStack(spacing: 0) {
                // Top zone: Header, challenge, input (fixed height)
                VStack(spacing: 12) {
                    // Header
                    headerView

                    // Challenge area (compact version)
                    compactChallengeView

                    // Input section
                    if !game.gameWon {
                        inputSection
                    }
                }
                .padding(.top, 40)

                // Middle zone: Word chain in scrollable area with fixed max height
                ScrollView(.horizontal, showsIndicators: false) {
                    WordChainView(
                        wordChain: game.wordChain,
                        targetWord: game.targetWord,
                        gameWon: game.gameWon,
                        gaveUp: game.gaveUp,
                        optimalPath: game.optimalPath
                    )
                    .padding(.horizontal, 40)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: 80)

                Spacer(minLength: 0)

                // Status message (fixed position above buttons)
                if !game.statusMessage.isEmpty {
                    statusMessageView
                        .padding(.bottom, 8)
                }

                // Bottom zone: Fixed buttons with goal in center
                HStack(alignment: .bottom) {
                    leftButtonsView

                    Spacer()

                    // Goal/Status display (centered at bottom)
                    Group {
                        if game.gameWon {
                            if game.gaveUp {
                                Text("Solution: \(game.optimalGuessCount) step\(game.optimalGuessCount != 1 ? "s" : "")")
                                    .foregroundColor(.orange)
                            } else {
                                Text("Solved in \(game.userGuessCount) step\(game.userGuessCount != 1 ? "s" : "")!")
                                    .foregroundColor(Color(nsColor: NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)))
                            }
                        } else {
                            Text("Goal: \(game.optimalGuessCount) step\(game.optimalGuessCount != 1 ? "s" : "")")
                                .foregroundColor(typewriterLightBrown)
                        }
                    }
                    .font(.custom("American Typewriter", size: 14).weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(6)

                    Spacer()

                    rightButtonsView
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 900, minHeight: 502)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newGame)) { _ in
            game.newChallenge()
            resetHints()
            isInputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .undoWord)) { _ in
            game.undo()
            isInputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .flipDirection)) { _ in
            game.flipDirection()
            isInputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .getHint)) { _ in
            openWindow(id: "hint")
        }
        .onReceive(NotificationCenter.default.publisher(for: .giveUp)) { _ in
            game.giveUp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .loadCustomWordList)) { _ in
            showingFileImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .setDifficulty)) { notification in
            if let difficulty = notification.object as? DifficultyLevel {
                game.setDifficulty(difficulty)
                isInputFocused = true
            }
        }
    }

    // Typewriter brown color used throughout
    private let typewriterBrown = Color(nsColor: NSColor(calibratedRed: 0.25, green: 0.2, blue: 0.15, alpha: 1.0))
    private let typewriterLightBrown = Color(nsColor: NSColor(calibratedRed: 0.4, green: 0.35, blue: 0.3, alpha: 1.0))
    private let ladderBrown = Color(nsColor: NSColor(calibratedRed: 0.7, green: 0.45, blue: 0.2, alpha: 1.0))

    // MARK: - Header View
    private var headerView: some View {
        Text("word golf")
            .font(.custom("American Typewriter", size: 56).weight(.semibold).italic())
            .foregroundColor(ladderBrown)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.85))
            .cornerRadius(8)
    }

    // MARK: - Compact Challenge View (space-efficient)
    private var compactChallengeView: some View {
        HStack(spacing: 8) {
            // Current word box (wood-style like iOS)
            Text(game.currentWord)
                .font(.custom("American Typewriter", size: 20).bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.45, blue: 0.3, alpha: 1.0)),
                                    Color(nsColor: NSColor(calibratedRed: 0.5, green: 0.35, blue: 0.2, alpha: 1.0))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: NSColor(calibratedRed: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 2)

            Text("»")
                .font(.custom("American Typewriter", size: 22).bold())
                .foregroundColor(ladderBrown)

            // Target word box (wood-style like iOS)
            Text(game.targetWord)
                .font(.custom("American Typewriter", size: 20).bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.45, blue: 0.3, alpha: 1.0)),
                                    Color(nsColor: NSColor(calibratedRed: 0.5, green: 0.35, blue: 0.2, alpha: 1.0))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: NSColor(calibratedRed: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 2)
        }
    }

    // MARK: - Input Section
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Enter word", text: $game.currentInput)
                .textFieldStyle(.roundedBorder)
                .font(.custom("American Typewriter", size: 16))
                .focused($isInputFocused)
                .onSubmit {
                    submitWord()
                }
                .frame(width: 400, height: 36)
                .background(Color.white.opacity(0.9))
                .cornerRadius(6)
                .onChange(of: game.currentInput) { oldValue, newValue in
                    // Limit to 4 characters and lowercase
                    if newValue.count > 4 {
                        game.currentInput = String(newValue.prefix(4))
                    }
                    game.currentInput = game.currentInput.lowercased()
                }

            Button(action: submitWord) {
                Text("→")
                    .font(.custom("American Typewriter", size: 18).bold())
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(typewriterBrown)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [])
            .help("Submit word")
        }
        .padding(.horizontal, 40)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Status Message View
    private var statusMessageView: some View {
        Text(game.statusMessage)
            .font(.custom("American Typewriter", size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.85))
            .cornerRadius(6)
    }

    // MARK: - Left Buttons View (fixed position)
    private var leftButtonsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !game.gameWon {
                // Undo button
                Button(action: {
                    game.undo()
                    isInputFocused = true
                }) {
                    Text("Undo")
                        .font(.custom("American Typewriter", size: 13))
                        .foregroundColor(typewriterBrown)
                        .frame(width: 70)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.9))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(typewriterLightBrown, lineWidth: 1)
                )
                .disabled(!game.canUndo)
                .opacity(game.canUndo ? 1.0 : 0.5)
                .help("Undo last word (⌘Z)")

                // Flip button
                Button(action: {
                    game.flipDirection()
                    isInputFocused = true
                }) {
                    Text("Flip")
                        .font(.custom("American Typewriter", size: 13))
                        .foregroundColor(typewriterBrown)
                        .frame(width: 70)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.9))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(typewriterLightBrown, lineWidth: 1)
                )
                .disabled(!game.canFlip)
                .opacity(game.canFlip ? 1.0 : 0.5)
                .help("Swap start and target words (⌘F)")

                // Give Up button
                Button(action: {
                    game.giveUp()
                }) {
                    Text("Give Up")
                        .font(.custom("American Typewriter", size: 13))
                        .foregroundColor(typewriterBrown)
                        .frame(width: 70)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.9))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(typewriterLightBrown, lineWidth: 1)
                )
                .help("Show the solution (⌘⇧G)")
            } else {
                // New Game button when game is won
                Button(action: {
                    game.newChallenge()
                    resetHints()
                    isInputFocused = true
                }) {
                    Text("New Game")
                        .font(.custom("American Typewriter", size: 14).bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(typewriterBrown)
                .cornerRadius(6)
                .keyboardShortcut("n", modifiers: .command)
                .help("Start a new game (⌘N)")
            }
        }
    }

    // MARK: - Right Buttons View (fixed position)
    private var rightButtonsView: some View {
        VStack(alignment: .center, spacing: 8) {
            // Help button (centered over hint buttons)
            Button(action: {
                showingExamplePopover.toggle()
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(typewriterBrown)
                    .frame(width: 70, height: 24)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingExamplePopover, arrowEdge: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Play")
                        .font(.custom("American Typewriter", size: 14).bold())
                    Text("Transform one word into another by changing one letter at a time. Each intermediate step must be a valid word.")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(.secondary)

                    Text("Example")
                        .font(.custom("American Typewriter", size: 14).bold())
                        .padding(.top, 4)
                    Text("HEAD → HEAL → TEAL → TELL → TALL → TAIL")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(.orange)

                    Text("Hints")
                        .font(.custom("American Typewriter", size: 14).bold())
                        .padding(.top, 4)
                    Text("Hints reveal words from the shortest solution path—not necessarily the next word in sequence.")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(width: 320)
            }

            if !game.gameWon {
                // First hint button
                if let hint = hint1Revealed {
                    Text(hint.uppercased())
                        .font(.custom("American Typewriter", size: 14).bold())
                        .foregroundColor(Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)))
                        .frame(width: 70)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.35, blue: 0.1, alpha: 0.5)), lineWidth: 1)
                        )
                } else {
                    Button(action: { revealHint(slot: 1) }) {
                        Text("Hint")
                            .font(.custom("American Typewriter", size: 13))
                            .foregroundColor(typewriterBrown)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(typewriterLightBrown, lineWidth: 1)
                    )
                    .disabled(!canGetHint(slot: 1))
                    .opacity(canGetHint(slot: 1) ? 1.0 : 0.5)
                }

                // Second hint button
                if let hint = hint2Revealed {
                    Text(hint.uppercased())
                        .font(.custom("American Typewriter", size: 14).bold())
                        .foregroundColor(Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.35, blue: 0.1, alpha: 1.0)))
                        .frame(width: 70)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(nsColor: NSColor(calibratedRed: 0.6, green: 0.35, blue: 0.1, alpha: 0.5)), lineWidth: 1)
                        )
                } else {
                    Button(action: { revealHint(slot: 2) }) {
                        Text("Hint")
                            .font(.custom("American Typewriter", size: 13))
                            .foregroundColor(typewriterBrown)
                            .frame(width: 70)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(typewriterLightBrown, lineWidth: 1)
                    )
                    .disabled(!canGetHint(slot: 2))
                    .opacity(canGetHint(slot: 2) ? 1.0 : 0.5)
                }
            }
        }
    }

    private func canGetHint(slot: Int) -> Bool {
        let revealed = slot == 1 ? hint1Revealed : hint2Revealed
        return revealed == nil && game.canGetHint
    }

    private func revealHint(slot: Int) {
        game.getHint()
        if let hint = game.hints.last {
            if slot == 1 {
                hint1Revealed = hint
            } else {
                hint2Revealed = hint
            }
        }
    }

    private func resetHints() {
        hint1Revealed = nil
        hint2Revealed = nil
    }

    // MARK: - Helper Methods
    private func submitWord() {
        game.submitWord(game.currentInput)
        isInputFocused = true
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                game.loadDictionary(from: url)
            }
        case .failure(let error):
            print("Error importing file: \(error)")
        }
    }

    // Public method for menu commands
    func loadCustomWordList() {
        showingFileImporter = true
    }
}

// #Preview {
//     ContentView()
//         .frame(width: 700, height: 600)
// }
