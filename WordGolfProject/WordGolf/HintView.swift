//
//  HintView.swift
//  WordGolf
//
//  Solver window - find the shortest path between any two words
//

import SwiftUI
import WordGolfCore

struct HintView: View {
    @EnvironmentObject var game: GameModel
    @State private var gameEnded = false
    @State private var showingWarning = false
    @Environment(\.dismiss) var dismiss

    // Solver state
    @StateObject private var solver = SolverModel()
    @State private var solverStartWord: String = ""
    @State private var solverEndWord: String = ""
    @FocusState private var solverStartFieldFocused: Bool

    // Typewriter colors
    private let typewriterBrown = Color(red: 0.25, green: 0.2, blue: 0.15)
    private let typewriterLightBrown = Color(red: 0.4, green: 0.35, blue: 0.3)
    private let cardBackground = Color(red: 0.95, green: 0.93, blue: 0.88)

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("solver")
                .font(.custom("American Typewriter", size: 32).italic())
                .foregroundColor(typewriterBrown)
                .padding(.top, 20)

            Text("Find the shortest path between any two words")
                .font(.custom("American Typewriter", size: 13))
                .foregroundColor(typewriterLightBrown)

            if !gameEnded {
                Text("Note: Using the solver will end the current game.")
                    .font(.custom("American Typewriter", size: 12))
                    .foregroundColor(.orange)
            }

            Divider()
                .padding(.horizontal, 30)

            // Input fields
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(typewriterLightBrown)
                    TextField("e.g., head", text: $solverStartWord)
                        .textFieldStyle(.roundedBorder)
                        .font(.custom("American Typewriter", size: 16))
                        .frame(width: 100)
                        .focused($solverStartFieldFocused)
                        .onChange(of: solverStartWord) { old, new in
                            solverStartWord = String(new.prefix(4)).lowercased()
                        }
                }

                Text("→")
                    .font(.custom("American Typewriter", size: 20))
                    .foregroundColor(typewriterLightBrown)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text("End")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(typewriterLightBrown)
                    TextField("e.g., tail", text: $solverEndWord)
                        .textFieldStyle(.roundedBorder)
                        .font(.custom("American Typewriter", size: 16))
                        .frame(width: 100)
                        .onChange(of: solverEndWord) { old, new in
                            solverEndWord = String(new.prefix(4)).lowercased()
                        }
                }
            }

            // Buttons row
            HStack(spacing: 16) {
                // Find Path button
                if gameEnded {
                    Button(action: { solveDirect() }) {
                        Text("Find Path")
                            .font(.custom("American Typewriter", size: 14).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(typewriterBrown)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(solverStartWord.count != 4 || solverEndWord.count != 4)
                    .opacity(solverStartWord.count == 4 && solverEndWord.count == 4 ? 1.0 : 0.5)
                } else {
                    Button(action: { showingWarning = true }) {
                        Text("Find Path")
                            .font(.custom("American Typewriter", size: 14).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(typewriterBrown)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(solverStartWord.count != 4 || solverEndWord.count != 4)
                    .opacity(solverStartWord.count == 4 && solverEndWord.count == 4 ? 1.0 : 0.5)
                }

                // Use Current Puzzle button
                Button {
                    solverStartWord = game.wordChain.first ?? game.currentWord
                    solverEndWord = game.targetWord
                } label: {
                    Text("Use Current Puzzle")
                        .font(.custom("American Typewriter", size: 14))
                        .foregroundColor(typewriterBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(typewriterLightBrown, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, 30)

            // Results area
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    if solver.isSearching {
                        HStack(spacing: 10) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.custom("American Typewriter", size: 14))
                                .foregroundColor(typewriterLightBrown)
                        }
                        .padding()
                    } else if let error = solver.errorMessage {
                        Text(error)
                            .font(.custom("American Typewriter", size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    } else if let path = solver.foundPath {
                        VStack(spacing: 12) {
                            // Success header
                            HStack(spacing: 8) {
                                Text("✓")
                                    .foregroundColor(.green)
                                Text("Path Found")
                                    .font(.custom("American Typewriter", size: 16).bold())
                                    .foregroundColor(.green)
                                Text("•")
                                    .foregroundColor(typewriterLightBrown)
                                Text("\(path.count - 1) steps")
                                    .font(.custom("American Typewriter", size: 14))
                                    .foregroundColor(typewriterLightBrown)
                            }

                            // Path display
                            FlowLayout(spacing: 6) {
                                ForEach(0..<path.count, id: \.self) { index in
                                    HStack(spacing: 4) {
                                        Text(path[index].uppercased())
                                            .font(.custom("American Typewriter", size: 14).bold())
                                            .foregroundColor(typewriterBrown)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                (index == 0 || index == path.count - 1) ?
                                                Color.orange.opacity(0.3) : Color.white
                                            )
                                            .cornerRadius(4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(
                                                        (index == 0 || index == path.count - 1) ?
                                                        Color.orange.opacity(0.5) : typewriterLightBrown.opacity(0.5),
                                                        lineWidth: 1
                                                    )
                                            )

                                        if index < path.count - 1 {
                                            Text("→")
                                                .font(.custom("American Typewriter", size: 14))
                                                .foregroundColor(typewriterLightBrown)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(typewriterLightBrown.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(cardBackground)
        .alert("Use Solver and End Game?", isPresented: $showingWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Use Solver", role: .destructive) {
                endGameAndUseSolver()
            }
        } message: {
            Text("Using the solver will immediately end the current game and show you its solution. You won't be able to continue playing this puzzle.")
        }
        .onAppear {
            gameEnded = game.gameWon
            solverStartWord = ""
            solverEndWord = ""
            solver.reset()
            solverStartFieldFocused = true
        }
    }

    private func solveDirect() {
        solver.findPath(from: solverStartWord, to: solverEndWord)
    }

    private func endGameAndUseSolver() {
        // End the current game
        game.giveUp()
        gameEnded = true

        // Now find the path for the solver query
        solver.findPath(from: solverStartWord, to: solverEndWord)
    }
}
