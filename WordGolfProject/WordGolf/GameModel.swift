//
//  GameModel.swift
//  WordGolf
//
//  Game logic and state management for Word Golf
//

import Foundation
import Combine

enum DifficultyLevel: Int, CaseIterable, Identifiable {
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case unlimited = 100

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .unlimited: return "Unlimited"
        default: return "\(rawValue) Steps"
        }
    }
}

class GameModel: ObservableObject {
    // MARK: - UserDefaults Keys
    private static let difficultyKey = "WordGolf.difficulty"

    // MARK: - Published Properties
    @Published var wordChain: [String] = []
    @Published var currentWord: String = ""
    @Published var targetWord: String = ""
    @Published var gameWon: Bool = false
    @Published var gaveUp: Bool = false
    @Published var statusMessage: String = ""
    @Published var hints: [String] = []
    @Published var hintsUsed: Int = 0
    @Published var currentInput: String = ""
    @Published var difficulty: DifficultyLevel {
        didSet {
            // Save difficulty to UserDefaults when changed
            UserDefaults.standard.set(difficulty.rawValue, forKey: Self.difficultyKey)
        }
    }

    // MARK: - Private Properties
    private var dictionary: Set<String> = []
    private var wordsArray: [String] = []
    private var neighborsMap: [String: [String]] = [:]
    private(set) var optimalPath: [String] = []

    // MARK: - Initialization
    init() {
        // Load saved difficulty from UserDefaults, default to 4 steps
        let savedDifficulty = UserDefaults.standard.integer(forKey: Self.difficultyKey)
        if savedDifficulty > 0,
           let level = DifficultyLevel(rawValue: savedDifficulty) {
            self.difficulty = level
        } else {
            self.difficulty = .four
        }

        loadDictionary()
        precomputeNeighbors()
        newChallenge()
    }

    // MARK: - Dictionary Management
    func loadDictionary(from fileURL: URL? = nil) {
        dictionary.removeAll()

        let url: URL
        if let fileURL = fileURL {
            url = fileURL
        } else {
            // Load from bundle
            guard let bundleURL = Bundle.main.url(forResource: "words", withExtension: "txt") else {
                print("Error: words.txt not found in bundle")
                return
            }
            url = bundleURL
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty && $0.count == 4 }

            dictionary = Set(words)
            wordsArray = Array(dictionary).sorted()

            precomputeNeighbors()
            newChallenge()
        } catch {
            print("Error loading dictionary: \(error)")
        }
    }

    private func precomputeNeighbors() {
        neighborsMap.removeAll()

        for word in dictionary {
            var neighbors: [String] = []

            for i in 0..<word.count {
                for char in "abcdefghijklmnopqrstuvwxyz" {
                    var chars = Array(word)
                    chars[i] = char
                    let candidate = String(chars)

                    if candidate != word && dictionary.contains(candidate) {
                        neighbors.append(candidate)
                    }
                }
            }

            neighborsMap[word] = neighbors
        }
    }

    // MARK: - Game Logic
    func newChallenge() {
        guard !wordsArray.isEmpty else { return }

        var path: [String]?
        var start = ""
        var end = ""
        let maxSteps = difficulty.rawValue

        // Keep trying until we find a path that fits the difficulty constraint
        var attempts = 0
        while path == nil && attempts < 100 {
            start = wordsArray.randomElement()!
            end = wordsArray.randomElement()!

            if start != end {
                if let foundPath = findShortestPath(from: start, to: end) {
                    let guessCount = foundPath.count - 2
                    if guessCount <= maxSteps {
                        path = foundPath
                    }
                }
            }
            attempts += 1
        }

        // Fallback: if we couldn't find a path within difficulty, use any path
        if path == nil {
            while path == nil {
                start = wordsArray.randomElement()!
                end = wordsArray.randomElement()!
                if start != end {
                    path = findShortestPath(from: start, to: end)
                }
            }
        }

        currentWord = start
        targetWord = end
        optimalPath = path!
        wordChain = [currentWord, targetWord]
        gameWon = false
        gaveUp = false
        statusMessage = ""
        hints = []
        hintsUsed = 0
        currentInput = ""
    }

    func setDifficulty(_ level: DifficultyLevel) {
        difficulty = level
        newChallenge()
    }

    func submitWord(_ guess: String) {
        let word = guess.lowercased().trimmingCharacters(in: .whitespaces)

        // Validate word exists in dictionary
        guard dictionary.contains(word) else {
            statusMessage = "Not a valid word!"
            return
        }

        // Check if trying to submit target word directly
        if word == targetWord {
            if wordChain.count == 2 {
                if isValidTransformation(from: currentWord, to: targetWord) {
                    gameWon = true
                    statusMessage = ""
                    currentInput = ""
                    return
                } else {
                    statusMessage = "You can only change one letter at a time!"
                    return
                }
            } else {
                statusMessage = "That word is already in the chain."
                return
            }
        }

        // Check if word already in chain
        if wordChain.contains(word) {
            statusMessage = "That word is already in the chain."
            return
        }

        // Validate transformation from previous word
        let previousWord = wordChain[wordChain.count - 2]
        guard isValidTransformation(from: previousWord, to: word) else {
            statusMessage = "You can only change one letter at a time!"
            return
        }

        // Insert word before target
        wordChain.insert(word, at: wordChain.count - 1)

        // Check if we've reached the target
        if isValidTransformation(from: word, to: targetWord) {
            gameWon = true
            statusMessage = ""
        } else {
            statusMessage = ""
        }

        currentInput = ""
    }

    func undo() {
        guard wordChain.count > 2 else { return }
        wordChain.remove(at: wordChain.count - 2)
        statusMessage = ""
    }

    func flipDirection() {
        guard wordChain.count == 2 else { return }

        swap(&currentWord, &targetWord)
        if let path = findShortestPath(from: currentWord, to: targetWord) {
            optimalPath = path
        }
        wordChain = [currentWord, targetWord]
    }

    func getHint() {
        guard hintsUsed < 2 else { return }

        let validHintWords = optimalPath.dropFirst().dropLast()
        let remainingWords = validHintWords.filter { !wordChain.contains($0) && !hints.contains($0) }

        guard let hintWord = remainingWords.randomElement() else { return }

        hints.append(hintWord)
        hintsUsed += 1
    }

    func giveUp() {
        gaveUp = true
        gameWon = true
    }

    // MARK: - Helper Methods
    func isValidTransformation(from word1: String, to word2: String) -> Bool {
        guard word1.count == word2.count else { return false }

        let chars1 = Array(word1)
        let chars2 = Array(word2)
        var diffCount = 0

        for i in 0..<chars1.count {
            if chars1[i] != chars2[i] {
                diffCount += 1
            }
        }

        return diffCount == 1
    }

    func findShortestPath(from start: String, to end: String, maxDepth: Int = 10) -> [String]? {
        var queue: [[String]] = [[start]]
        var visited: Set<String> = [start]
        var currentDepth = 1
        var pathsAtCurrentDepth = 1
        var pathsAtNextDepth = 0

        while !queue.isEmpty && currentDepth <= maxDepth {
            let path = queue.removeFirst()
            pathsAtCurrentDepth -= 1

            let currentWord = path.last!

            if currentWord == end {
                return path
            }

            if let neighbors = neighborsMap[currentWord] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        queue.append(path + [neighbor])
                        pathsAtNextDepth += 1
                    }
                }
            }

            if pathsAtCurrentDepth == 0 {
                currentDepth += 1
                pathsAtCurrentDepth = pathsAtNextDepth
                pathsAtNextDepth = 0
            }
        }

        return nil
    }

    // MARK: - Computed Properties
    var userGuessCount: Int {
        return max(0, wordChain.count - 2)
    }

    var optimalGuessCount: Int {
        return max(0, optimalPath.count - 2)
    }

    var canFlip: Bool {
        return wordChain.count == 2
    }

    var canUndo: Bool {
        return wordChain.count > 2 && !gameWon
    }

    var canGetHint: Bool {
        let remainingHints = optimalPath.dropFirst().dropLast().filter { !wordChain.contains($0) }
        return !gameWon && hintsUsed < 2 && !remainingHints.isEmpty
    }

    var optimalPathString: String {
        return optimalPath.joined(separator: " → ")
    }
}
