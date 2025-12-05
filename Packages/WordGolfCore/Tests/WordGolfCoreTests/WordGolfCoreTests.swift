//
//  WordGolfCoreTests.swift
//  WordGolfCore
//

import Testing
@testable import WordGolfCore

@Test func testDifficultyLevel() {
    #expect(DifficultyLevel.four.rawValue == 4)
    #expect(DifficultyLevel.unlimited.displayName == "Unlimited")
    #expect(DifficultyLevel.three.displayName == "3 Steps")
}

@Test func testValidTransformation() async {
    let game = await GameModel(storage: nil)
    #expect(await game.isValidTransformation(from: "head", to: "heal") == true)
    #expect(await game.isValidTransformation(from: "head", to: "tail") == false)
    #expect(await game.isValidTransformation(from: "cat", to: "bat") == true)
}
