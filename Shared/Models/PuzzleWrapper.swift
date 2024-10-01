//
//  PuzzleWrapper.swift
//  NewPuzzles
//
//  Created by Kevin on 9/30/24.
//

// Wrapper to make Puzzle Codable and RawRepresentable.

enum PuzzleWrapperError: Error {
    case invalidPuzzle
}

struct PuzzleWrapper {
    let puzzle: Puzzle
}

extension PuzzleWrapper: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        guard let puzzle = Puzzle(named: name) else {
            throw PuzzleWrapperError.invalidPuzzle
        }
        self.puzzle = puzzle
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(puzzle.name)
    }
}

extension PuzzleWrapper: RawRepresentable {
    var rawValue: String { puzzle.name }

    init?(rawValue: String) {
        guard let puzzle = Puzzle(named: rawValue) else { return nil }
        self.puzzle = puzzle
    }
}

extension PuzzleWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(puzzle.name)
    }
}

extension PuzzleWrapper: Identifiable {
    var id: String { puzzle.name }
}
