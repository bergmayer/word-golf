//
//  WordGolfApp.swift
//  WordGolf
//
//  Main application entry point with menu bar
//

import SwiftUI
import WordGolfCore

@main
struct WordGolfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var gameModel = GameModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 900, height: 502)
        .windowResizability(.contentSize)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("New Game") {
                    NotificationCenter.default.post(name: .newGame, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Menu("Difficulty") {
                    Toggle("3 Steps", isOn: Binding(
                        get: { gameModel.difficulty == .three },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.three) } }
                    ))
                    Toggle("4 Steps", isOn: Binding(
                        get: { gameModel.difficulty == .four },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.four) } }
                    ))
                    Toggle("5 Steps", isOn: Binding(
                        get: { gameModel.difficulty == .five },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.five) } }
                    ))
                    Toggle("6 Steps", isOn: Binding(
                        get: { gameModel.difficulty == .six },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.six) } }
                    ))
                    Toggle("7 Steps", isOn: Binding(
                        get: { gameModel.difficulty == .seven },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.seven) } }
                    ))
                    Toggle("Unlimited", isOn: Binding(
                        get: { gameModel.difficulty == .unlimited },
                        set: { if $0 { NotificationCenter.default.post(name: .setDifficulty, object: DifficultyLevel.unlimited) } }
                    ))
                }

                Divider()

                Button("Flip Direction") {
                    NotificationCenter.default.post(name: .flipDirection, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Solver...") {
                    NotificationCenter.default.post(name: .getHint, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Give Up") {
                    NotificationCenter.default.post(name: .giveUp, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Load Custom Word List...") {
                    NotificationCenter.default.post(name: .loadCustomWordList, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            // Edit menu - replace default undo/redo with our undo
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NotificationCenter.default.post(name: .undoWord, object: nil)
                }
                .keyboardShortcut("z", modifiers: .command)
            }

            // Help menu additions
            CommandGroup(replacing: .help) {
                Button("Word Golf Help") {
                    showHistoryWindow()
                }
            }

            // About menu in Application menu
            CommandGroup(replacing: .appInfo) {
                Button("About Word Golf") {
                    showAboutWindow()
                }
            }
        }

        // Solver window
        Window("Solver", id: "hint") {
            HintView()
                .environmentObject(gameModel)
        }
        .defaultSize(width: 550, height: 500)
        .windowResizability(.contentSize)
    }

    private func showAboutWindow() {
        let alert = NSAlert()
        alert.messageText = "Word Golf"
        alert.informativeText = """
        Transform one word into another by changing one letter at a time.

        Version 1.0
        Copyright 2025 John Bergmayer
        Licensed under GPL 3.0

        https://github.com/bergmayer/word-golf
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showHistoryWindow() {
        // Reuse existing window if available
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
           let existingWindow = appDelegate.helpWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // Create a window to display the help
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 750),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Word Golf"
        window.center()
        window.isReleasedWhenClosed = false

        // Store in AppDelegate
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.helpWindow = window
        }

        // Create text view
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width]
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 30, height: 30)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true

        // Create attributed string with formatting
        let attributedText = NSMutableAttributedString()

        // Main title
        let titleFont = NSFont.systemFont(ofSize: 24, weight: .light)
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.alignment = .natural
        titleParagraph.paragraphSpacing = 20
        attributedText.append(NSAttributedString(string: "About Word Golf\n", attributes: [
            .font: titleFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: titleParagraph
        ]))

        // Body text style
        let bodyFont = NSFont.systemFont(ofSize: 13)
        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.alignment = .natural
        bodyParagraph.paragraphSpacing = 12
        bodyParagraph.lineSpacing = 2

        // Intro paragraph
        attributedText.append(NSAttributedString(string: "Word Golf is a word puzzle game in which you transform one word into another by changing a single letter at a time. Each intermediate step must form a valid English word, and the goal is to complete the transformation in as few moves as possible.\n\n", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        // Section heading style
        let headingFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let headingParagraph = NSMutableParagraphStyle()
        headingParagraph.alignment = .natural
        headingParagraph.paragraphSpacing = 10
        headingParagraph.paragraphSpacingBefore = 10

        // How to Play section
        attributedText.append(NSAttributedString(string: "How to Play\n", attributes: [
            .font: headingFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: headingParagraph
        ]))

        attributedText.append(NSAttributedString(string: """
        1. You are given a starting word and a target word
        2. Change exactly one letter at a time to form a new valid word
        3. Continue until you reach the target word
        4. The fewer steps you use, the better your score

        The "optimal" solution shown is the shortest possible path. Can you match it?\n\n
        """, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        // Example Puzzles section
        attributedText.append(NSAttributedString(string: "Example Puzzles\n", attributes: [
            .font: headingFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: headingParagraph
        ]))

        // Example chain style
        let exampleFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        let exampleParagraph = NSMutableParagraphStyle()
        exampleParagraph.alignment = .natural
        exampleParagraph.paragraphSpacing = 8

        attributedText.append(NSAttributedString(string: "HEAD → TAIL (4 steps)\n", attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: exampleParagraph
        ]))
        attributedText.append(NSAttributedString(string: "HEAD → HEAL → TEAL → TELL → TALL → TAIL\n\n", attributes: [
            .font: exampleFont,
            .foregroundColor: NSColor.systemOrange,
            .paragraphStyle: exampleParagraph
        ]))

        attributedText.append(NSAttributedString(string: "LOVE → HATE (4 steps)\n", attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: exampleParagraph
        ]))
        attributedText.append(NSAttributedString(string: "LOVE → LODE → CODE → CADE → CATE → HATE\n\n", attributes: [
            .font: exampleFont,
            .foregroundColor: NSColor.systemOrange,
            .paragraphStyle: exampleParagraph
        ]))

        attributedText.append(NSAttributedString(string: "COLD → WARM (4 steps)\n", attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: exampleParagraph
        ]))
        attributedText.append(NSAttributedString(string: "COLD → COLE → CORE → WORE → WORM → WARM\n\n", attributes: [
            .font: exampleFont,
            .foregroundColor: NSColor.systemOrange,
            .paragraphStyle: exampleParagraph
        ]))

        // History section intro
        attributedText.append(NSAttributedString(string: "History\n", attributes: [
            .font: headingFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: headingParagraph
        ]))

        // The Game in Pale Fire subsection
        let subheadingFont = NSFont.systemFont(ofSize: 14, weight: .medium)
        attributedText.append(NSAttributedString(string: "The Game in Pale Fire\n", attributes: [
            .font: subheadingFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: headingParagraph
        ]))

        attributedText.append(NSAttributedString(string: "The name \"word golf\" comes from Vladimir Nabokov's 1962 novel ", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        let italicDescriptor = NSFont.systemFont(ofSize: 13, weight: .medium).fontDescriptor.withSymbolicTraits(.italic)
        let italicFont = NSFont(descriptor: italicDescriptor, size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .medium)
        attributedText.append(NSAttributedString(string: "Pale Fire", attributes: [
            .font: italicFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        attributedText.append(NSAttributedString(string: ". Nabokov has the narrator Charles Kinbote describe the game as a pastime of the poet John Shade:\n\n", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        // Quote style
        let quoteFont = NSFont.systemFont(ofSize: 13)
        let quoteParagraph = NSMutableParagraphStyle()
        quoteParagraph.alignment = .natural
        quoteParagraph.paragraphSpacing = 12
        quoteParagraph.firstLineHeadIndent = 30
        quoteParagraph.headIndent = 30
        quoteParagraph.tailIndent = -30

        attributedText.append(NSAttributedString(string: "\"Some of my records are: hate—love in three, lass—male in four, and live—dead in five (with 'lend' in the middle).\"\n\n", attributes: [
            .font: quoteFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: quoteParagraph
        ]))

        // Lewis Carroll subsection
        attributedText.append(NSAttributedString(string: "Lewis Carroll's Doublets\n", attributes: [
            .font: subheadingFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: headingParagraph
        ]))

        attributedText.append(NSAttributedString(string: "While this game was inspired by Nabokov, the puzzle itself was invented by Lewis Carroll (Charles Dodgson) on Christmas Day, 1877. Carroll originally called the game \"Word-links\" and devised it for Julia and Ethel Arnold. He first published word ladder puzzles under the name \"Doublets\" in ", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        let vanityFairDescriptor = NSFont.systemFont(ofSize: 13, weight: .medium).fontDescriptor.withSymbolicTraits(.italic)
        let vanityFairFont = NSFont(descriptor: vanityFairDescriptor, size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .medium)
        attributedText.append(NSAttributedString(string: "Vanity Fair", attributes: [
            .font: vanityFairFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        attributedText.append(NSAttributedString(string: " magazine on March 29, 1879, and later that year collected them in a book published by Macmillan.\n\nThe puzzle quickly became popular in Victorian England, and the game has appeared under many names over the years: Doublets, word-links, laddergrams, paragrams, and Stepword (as it was known when revived by ", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        let canberraDescriptor = NSFont.systemFont(ofSize: 13, weight: .medium).fontDescriptor.withSymbolicTraits(.italic)
        let canberraFont = NSFont(descriptor: canberraDescriptor, size: 13) ?? NSFont.systemFont(ofSize: 13, weight: .medium)
        attributedText.append(NSAttributedString(string: "The Canberra Times", attributes: [
            .font: canberraFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        attributedText.append(NSAttributedString(string: " in the 1990s).\n\nDonald Knuth later applied computer analysis to five-letter word ladders, noting that some words—like \"aloof\"—have no neighbors and cannot be connected to any other word. Fittingly, he observed, \"aloof\" is itself aloof.\n\n", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        // Link
        attributedText.append(NSAttributedString(string: "For more on the history and mathematics of word ladders:\n", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bodyParagraph
        ]))

        let linkParagraph = NSMutableParagraphStyle()
        linkParagraph.alignment = .natural
        linkParagraph.paragraphSpacing = 12

        attributedText.append(NSAttributedString(string: "https://en.wikipedia.org/wiki/Word_ladder", attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.linkColor,
            .link: URL(string: "https://en.wikipedia.org/wiki/Word_ladder")!,
            .paragraphStyle: linkParagraph
        ]))

        textView.textStorage?.setAttributedString(attributedText)

        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)

        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var helpWindow: NSWindow?
    // Index card aspect ratio: 2752:1536 = 1.79167
    private let aspectRatio: CGFloat = 2752.0 / 1536.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance with slight delay to ensure SwiftUI has finished setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true

                // Set fixed size (not resizable)
                let fixedWidth: CGFloat = 900
                let fixedHeight = fixedWidth / self.aspectRatio
                window.setContentSize(NSSize(width: fixedWidth, height: fixedHeight))

                // Remove resizable from style mask
                window.styleMask.remove(.resizable)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newGame = Notification.Name("newGame")
    static let undoWord = Notification.Name("undoWord")
    static let flipDirection = Notification.Name("flipDirection")
    static let getHint = Notification.Name("getHint")
    static let giveUp = Notification.Name("giveUp")
    static let loadCustomWordList = Notification.Name("loadCustomWordList")
    static let setDifficulty = Notification.Name("setDifficulty")
}
