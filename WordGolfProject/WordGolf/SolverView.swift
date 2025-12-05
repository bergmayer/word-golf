//
//  SolverView.swift
//  WordGolf
//
//  Word Golf Solver - Find paths between any two words
//

import SwiftUI
import WordGolfCore

struct SolverView: View {
    @StateObject private var solver = SolverModel()
    @State private var startWord: String = ""
    @State private var endWord: String = ""
    @FocusState private var startFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    // Access to current game for "Use Current Puzzle" button
    var currentStartWord: String?
    var currentEndWord: String?

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

            Divider()
                .padding(.horizontal, 30)

            // Input fields
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start")
                        .font(.custom("American Typewriter", size: 12))
                        .foregroundColor(typewriterLightBrown)
                    TextField("e.g., head", text: $startWord)
                        .textFieldStyle(.roundedBorder)
                        .font(.custom("American Typewriter", size: 16))
                        .frame(width: 100)
                        .focused($startFieldFocused)
                        .onChange(of: startWord) { old, new in
                            startWord = String(new.prefix(4)).lowercased()
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
                    TextField("e.g., tail", text: $endWord)
                        .textFieldStyle(.roundedBorder)
                        .font(.custom("American Typewriter", size: 16))
                        .frame(width: 100)
                        .onChange(of: endWord) { old, new in
                            endWord = String(new.prefix(4)).lowercased()
                        }
                }
            }

            // Buttons row
            HStack(spacing: 16) {
                // Find Path button
                Button(action: solve) {
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
                .disabled(startWord.count != 4 || endWord.count != 4)
                .opacity(startWord.count == 4 && endWord.count == 4 ? 1.0 : 0.5)

                // Use Current Puzzle button
                if let start = currentStartWord, let end = currentEndWord {
                    Button {
                        startWord = start
                        endWord = end
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
        .onAppear {
            startWord = ""
            endWord = ""
            solver.reset()
            startFieldFocused = true
        }
    }

    private func solve() {
        solver.findPath(from: startWord, to: endWord)
    }
}

// Simple flow layout for wrapping words
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                sizes.append(size)

                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x - spacing)
            }

            self.size.height = y + lineHeight
        }
    }
}

class SolverModel: ObservableObject {
    @Published var foundPath: [String]?
    @Published var errorMessage: String?
    @Published var isSearching: Bool = false

    private var dictionary: Set<String> = []
    private var neighborsMap: [String: [String]] = [:]
    private var searchTask: DispatchWorkItem?
    private var isCancelled = false

    init() {
        loadDictionary()
    }

    deinit {
        // Cancel any ongoing search when deallocating
        isCancelled = true
        searchTask?.cancel()
    }

    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "txt") else {
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty && $0.count == 4 }

            dictionary = Set(words)
            precomputeNeighbors()
        } catch {
            errorMessage = "Error loading dictionary"
        }
    }

    private func precomputeNeighbors() {
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

    func reset() {
        isCancelled = true
        searchTask?.cancel()
        searchTask = nil
        isCancelled = false
        foundPath = nil
        errorMessage = nil
        isSearching = false
    }

    func findPath(from start: String, to end: String) {
        // Cancel any existing search
        isCancelled = true
        searchTask?.cancel()
        isCancelled = false

        foundPath = nil
        errorMessage = nil
        isSearching = true

        // Create a cancellable work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Validate words
            if !self.dictionary.contains(start) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "'\(start)' is not in the dictionary"
                    self.isSearching = false
                }
                return
            }

            if !self.dictionary.contains(end) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.errorMessage = "'\(end)' is not in the dictionary"
                    self.isSearching = false
                }
                return
            }

            if start == end {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.foundPath = [start]
                    self.isSearching = false
                }
                return
            }

            // BFS
            var queue: [[String]] = [[start]]
            var visited: Set<String> = [start]

            while !queue.isEmpty {
                // Check if cancelled
                if self.isCancelled { return }

                let path = queue.removeFirst()
                let current = path.last!

                if current == end {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.foundPath = path
                        self.isSearching = false
                    }
                    return
                }

                if let neighbors = self.neighborsMap[current] {
                    for neighbor in neighbors {
                        if !visited.contains(neighbor) {
                            visited.insert(neighbor)
                            queue.append(path + [neighbor])
                        }
                    }
                }
            }

            // No path found
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "No path exists between '\(start)' and '\(end)'"
                self.isSearching = false
            }
        }

        searchTask = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
}
