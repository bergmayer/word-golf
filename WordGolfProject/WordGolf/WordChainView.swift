//
//  WordChainView.swift
//  WordGolf
//
//  Horizontal ladder-style word chain display for Mac
//

import SwiftUI

struct WordChainView: View {
    let wordChain: [String]
    let targetWord: String
    let gameWon: Bool
    let gaveUp: Bool
    let optimalPath: [String]

    private let ladderColor = Color(nsColor: NSColor(calibratedRed: 0.7, green: 0.45, blue: 0.2, alpha: 1.0))
    private let typewriterBrown = Color(nsColor: NSColor(calibratedRed: 0.25, green: 0.2, blue: 0.15, alpha: 1.0))

    var body: some View {
        let displayWords = buildDisplayWords()

        VStack(spacing: 0) {
            // Top rail
            HStack(spacing: 0) {
                ForEach(Array(displayWords.enumerated()), id: \.offset) { index, wordInfo in
                    if index > 0 {
                        // Rail connector - dashed before last word until game is complete
                        let isLastWord = index == displayWords.count - 1
                        let showDashedRail = isLastWord && !gameWon && !gaveUp

                        if showDashedRail {
                            DottedRail()
                                .frame(width: 40, height: 4)
                        } else {
                            Rectangle()
                                .fill(ladderColor)
                                .frame(width: 40, height: 4)
                        }
                    }

                    // Word segment top
                    Rectangle()
                        .fill(ladderColor)
                        .frame(width: wordWidth(for: wordInfo.word), height: 4)
                }
            }

            // Words row with arrows
            HStack(spacing: 0) {
                ForEach(Array(displayWords.enumerated()), id: \.offset) { index, wordInfo in
                    if index > 0 {
                        // Arrow between words - dashed before last word until game is complete
                        let isLastWord = index == displayWords.count - 1
                        let showDashedArrow = isLastWord && !gameWon && !gaveUp

                        if showDashedArrow {
                            // Dashed arrow before target
                            Text("⇢")
                                .font(.custom("American Typewriter", size: 28).weight(.medium))
                                .foregroundColor(ladderColor.opacity(0.5))
                                .frame(width: 40, height: 50)
                        } else {
                            Text("→")
                                .font(.custom("American Typewriter", size: 28).weight(.medium))
                                .foregroundColor(ladderColor)
                                .frame(width: 40, height: 50)
                        }
                    }

                    // Word box
                    let isLastWord = index == displayWords.count - 1
                    let isPlaceholderStyle = isLastWord && !gameWon && !gaveUp

                    Text(wordInfo.word)
                        .font(.custom("American Typewriter", size: 26).weight(.medium))
                        .foregroundColor(isPlaceholderStyle ? ladderColor : typewriterBrown)
                        .frame(width: wordWidth(for: wordInfo.word), height: 50)
                        .background(isPlaceholderStyle ? Color.white.opacity(0.4) : Color.white.opacity(0.85))
                }
            }

            // Bottom rail
            HStack(spacing: 0) {
                ForEach(Array(displayWords.enumerated()), id: \.offset) { index, wordInfo in
                    if index > 0 {
                        // Rail connector - dashed before last word until game is complete
                        let isLastWord = index == displayWords.count - 1
                        let showDashedRail = isLastWord && !gameWon && !gaveUp

                        if showDashedRail {
                            DottedRail()
                                .frame(width: 40, height: 4)
                        } else {
                            Rectangle()
                                .fill(ladderColor)
                                .frame(width: 40, height: 4)
                        }
                    }

                    // Word segment bottom
                    Rectangle()
                        .fill(ladderColor)
                        .frame(width: wordWidth(for: wordInfo.word), height: 4)
                }
            }
        }
    }

    private func wordWidth(for word: String) -> CGFloat {
        return CGFloat(max(word.count * 22, 90))
    }

    private func buildDisplayWords() -> [WordInfo] {
        var words: [WordInfo] = []

        // If gave up, show optimal path; otherwise show user's word chain
        let chainToShow = gaveUp ? optimalPath : wordChain

        for word in chainToShow {
            let isTargetWord = word.lowercased() == targetWord.lowercased()
            words.append(WordInfo(word: word, isTarget: isTargetWord, isPlaceholder: false))
        }

        // Add target at end if not yet reached and not gave up
        let reachedTarget = chainToShow.last?.lowercased() == targetWord.lowercased()
        if !reachedTarget && !gameWon && !gaveUp {
            words.append(WordInfo(word: targetWord, isTarget: true, isPlaceholder: true))
        }

        return words
    }
}

struct WordInfo: Identifiable {
    let id = UUID()
    let word: String
    let isTarget: Bool
    let isPlaceholder: Bool
}

// Dotted rail for incomplete connections
struct DottedRail: View {
    private let ladderColor = Color(nsColor: NSColor(calibratedRed: 0.7, green: 0.45, blue: 0.2, alpha: 1.0))

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
            }
            .stroke(style: StrokeStyle(lineWidth: 4, dash: [6, 4]))
            .foregroundColor(ladderColor)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        WordChainView(
            wordChain: ["head", "heal", "teal"],
            targetWord: "tail",
            gameWon: false,
            gaveUp: false,
            optimalPath: []
        )

        WordChainView(
            wordChain: ["head", "heal", "teal", "tell", "tall", "tail"],
            targetWord: "tail",
            gameWon: true,
            gaveUp: false,
            optimalPath: []
        )
    }
    .padding()
    .background(Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.88, alpha: 1.0)))
}
