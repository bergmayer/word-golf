//
//  GameModel.swift
//  WordGolfCore
//
//  Game logic and state management for Word Golf
//

import Foundation
import Combine

/// Protocol for persisting game settings
public protocol GameSettingsStorage {
    func loadDifficulty() -> DifficultyLevel?
    func saveDifficulty(_ level: DifficultyLevel)
}

/// Default storage using UserDefaults
public class UserDefaultsStorage: GameSettingsStorage {
    private static let difficultyKey = "WordGolf.difficulty"

    public init() {}

    public func loadDifficulty() -> DifficultyLevel? {
        let savedValue = UserDefaults.standard.integer(forKey: Self.difficultyKey)
        if savedValue > 0 {
            return DifficultyLevel(rawValue: savedValue)
        }
        return nil
    }

    public func saveDifficulty(_ level: DifficultyLevel) {
        UserDefaults.standard.set(level.rawValue, forKey: Self.difficultyKey)
    }
}

@MainActor
public class GameModel: ObservableObject {
    // MARK: - Constants
    private enum Constants {
        static let wordLength = 4
        static let maxChallengeAttempts = 100
        static let maxFallbackAttempts = 1000
        static let maxBfsDepth = 10
        static let maxHints = 2
    }

    // MARK: - Published Properties
    @Published public var wordChain: [String] = []
    @Published public var currentWord: String = ""
    @Published public var targetWord: String = ""
    @Published public var gameWon: Bool = false
    @Published public var gaveUp: Bool = false
    @Published public var statusMessage: String = ""
    @Published public var hints: [String] = []
    @Published public var hintsUsed: Int = 0
    @Published public var currentInput: String = ""
    @Published public var difficulty: DifficultyLevel {
        didSet {
            storage?.saveDifficulty(difficulty)
        }
    }

    // MARK: - Private Properties
    private var dictionary: Set<String> = []
    private var wordsArray: [String] = []
    private var neighborsMap: [String: [String]] = [:]
    private(set) public var optimalPath: [String] = []
    private var storage: GameSettingsStorage?

    // MARK: - Initialization
    public init(storage: GameSettingsStorage? = UserDefaultsStorage()) {
        self.storage = storage
        self.difficulty = storage?.loadDifficulty() ?? .four
        loadDictionary()
        precomputeNeighbors()
        newChallenge()
    }

    // MARK: - Dictionary Management
    public func loadDictionary(from fileURL: URL? = nil) {
        dictionary.removeAll()

        let url: URL
        if let fileURL = fileURL {
            url = fileURL
        } else {
            // Load from bundle - try package bundle first, then main bundle
            if let bundleURL = Bundle.module.url(forResource: "words", withExtension: "txt") {
                url = bundleURL
            } else if let mainBundleURL = Bundle.main.url(forResource: "words", withExtension: "txt") {
                url = mainBundleURL
            } else {
                print("Error: words.txt not found in bundle")
                return
            }
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty && $0.count == Constants.wordLength }

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
    public func newChallenge() {
        guard !wordsArray.isEmpty else { return }

        var path: [String]?
        var start = ""
        var end = ""
        let maxSteps = difficulty.rawValue

        // Keep trying until we find a path that fits the difficulty constraint
        var attempts = 0
        while path == nil && attempts < Constants.maxChallengeAttempts {
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
        // Limit attempts to avoid infinite loop with disconnected word graphs
        if path == nil {
            var fallbackAttempts = 0
            while path == nil && fallbackAttempts < Constants.maxFallbackAttempts {
                start = wordsArray.randomElement()!
                end = wordsArray.randomElement()!
                if start != end {
                    path = findShortestPath(from: start, to: end)
                }
                fallbackAttempts += 1
            }
        }

        // Final fallback: if still no path, create a trivial one-step challenge
        // This handles edge cases like very small or disconnected dictionaries
        if path == nil {
            if let connectedWord = findAnyConnectedPair() {
                start = connectedWord.0
                end = connectedWord.1
                path = [start, end]
            } else {
                // Dictionary has no connected words - use same word (degenerate case)
                start = wordsArray.first!
                end = start
                path = [start]
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

    /// Find any two words that are connected (one letter apart)
    private func findAnyConnectedPair() -> (String, String)? {
        for (word, neighbors) in neighborsMap {
            if let neighbor = neighbors.first {
                return (word, neighbor)
            }
        }
        return nil
    }

    public func setDifficulty(_ level: DifficultyLevel) {
        difficulty = level
        newChallenge()
    }

    public func submitWord(_ guess: String) {
        let word = guess.lowercased().trimmingCharacters(in: .whitespaces)

        // Validate word exists in dictionary
        guard dictionary.contains(word) else {
            statusMessage = "Not a playable word!"
            currentInput = ""
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
                    currentInput = ""
                    return
                }
            } else {
                statusMessage = "That word is already in the chain."
                currentInput = ""
                return
            }
        }

        // Check if word already in chain
        if wordChain.contains(word) {
            statusMessage = "That word is already in the chain."
            currentInput = ""
            return
        }

        // Validate transformation from previous word
        let previousWord = wordChain[wordChain.count - 2]
        guard isValidTransformation(from: previousWord, to: word) else {
            statusMessage = "You can only change one letter at a time!"
            currentInput = ""
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

    public func undo() {
        guard wordChain.count > 2 else { return }
        wordChain.remove(at: wordChain.count - 2)
        statusMessage = ""
    }

    public func flipDirection() {
        guard wordChain.count == 2 else { return }

        swap(&currentWord, &targetWord)
        if let path = findShortestPath(from: currentWord, to: targetWord) {
            optimalPath = path
        }
        wordChain = [currentWord, targetWord]
    }

    public func getHint() {
        guard hintsUsed < Constants.maxHints else { return }

        let validHintWords = optimalPath.dropFirst().dropLast()
        let remainingWords = validHintWords.filter { !wordChain.contains($0) && !hints.contains($0) }

        guard let hintWord = remainingWords.randomElement() else { return }

        hints.append(hintWord)
        hintsUsed += 1
    }

    public func giveUp() {
        gaveUp = true
        gameWon = true
    }

    // MARK: - Helper Methods
    public func isValidTransformation(from word1: String, to word2: String) -> Bool {
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

    /// BFS using parent pointers for O(V) memory instead of O(V * path_length)
    public func findShortestPath(from start: String, to end: String, maxDepth: Int = 10) -> [String]? {
        // Use parent pointers instead of storing full paths to reduce memory allocations
        var parent: [String: String?] = [start: nil]
        var queue: [String] = [start]
        var currentDepth = 0
        var nodesAtCurrentDepth = 1
        var nodesAtNextDepth = 0

        while !queue.isEmpty && currentDepth <= maxDepth {
            let current = queue.removeFirst()
            nodesAtCurrentDepth -= 1

            if current == end {
                // Reconstruct path from parent pointers
                return reconstructPath(from: start, to: end, parent: parent)
            }

            if let neighbors = neighborsMap[current] {
                for neighbor in neighbors where parent[neighbor] == nil {
                    parent[neighbor] = current
                    queue.append(neighbor)
                    nodesAtNextDepth += 1
                }
            }

            if nodesAtCurrentDepth == 0 {
                currentDepth += 1
                nodesAtCurrentDepth = nodesAtNextDepth
                nodesAtNextDepth = 0
            }
        }

        return nil
    }

    /// Reconstruct path from parent pointers
    private func reconstructPath(from start: String, to end: String, parent: [String: String?]) -> [String] {
        var path: [String] = []
        var current: String? = end

        while let node = current {
            path.append(node)
            current = parent[node] ?? nil
        }

        return path.reversed()
    }

    // MARK: - Computed Properties
    public var userGuessCount: Int {
        return max(0, wordChain.count - 2)
    }

    public var optimalGuessCount: Int {
        return max(0, optimalPath.count - 2)
    }

    public var canFlip: Bool {
        return wordChain.count == 2
    }

    public var canUndo: Bool {
        return wordChain.count > 2 && !gameWon
    }

    public var canGetHint: Bool {
        let remainingHints = optimalPath.dropFirst().dropLast().filter { !wordChain.contains($0) }
        return !gameWon && hintsUsed < Constants.maxHints && !remainingHints.isEmpty
    }

    public var optimalPathString: String {
        return optimalPath.joined(separator: " → ")
    }
}
