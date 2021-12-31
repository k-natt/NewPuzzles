//
//  GameViewModel.swift
//  NewPuzzles
//
//  Created by Kevin on 12/30/21.
//

import Foundation

class GameViewModel: ObservableObject {
    @Published var statusText: String?
    @Published var canUndo = false
    @Published var canRedo = false

    let puzzle: Puzzle
    let frontend: PuzzleFrontend

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.frontend = PuzzleFrontend(for: puzzle)
    }
}
