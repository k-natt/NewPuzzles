//
//  GameViewModel.swift
//  NewPuzzles
//
//  Created by Kevin on 12/30/21.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    let puzzleName: String
    let puzzleHelpURL: URL?
    let puzzleButtons: [PuzzleButton]

    @Published var statusText: String?
    @Published var wantsStatusBar = false
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var canSolve = false
    @Published var inProgress = false

    @AppStorage("") var saveState: Data?

    let puzzle: Puzzle
    let frontend: PuzzleFrontend

    init(puzzle: Puzzle) {
        self._saveState = AppStorage("\(puzzle.name)-save")
        self.puzzle = puzzle
        self.puzzleName = puzzle.name
        self.frontend = PuzzleFrontend(for: puzzle)
        self.puzzleHelpURL = Bundle.main.url(forResource: puzzle.helpName, withExtension: "html")
        self.puzzleButtons = frontend.buttons

        frontend.publisher(for: \.canUndo).assign(to: &$canUndo)
        frontend.publisher(for: \.canRedo).assign(to: &$canRedo)
        frontend.publisher(for: \.canSolve).assign(to: &$canSolve)
        frontend.publisher(for: \.inProgress).assign(to: &$inProgress)
        frontend.publisher(for: \.statusText).assign(to: &$statusText)
        frontend.publisher(for: \.wantsStatusBar).assign(to: &$wantsStatusBar)

        NotificationCenter.default.addObserver(self, selector: #selector(save(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

        if let saveState = saveState {
            frontend.restore(saveState)
        }
    }

    @objc private func save(_ notification: NSNotification) {
        save()
    }

    func save() {
        self.saveState = self.frontend.save()
    }

    func undo() {
        frontend.undo()
    }

    func redo() {
        frontend.redo()
    }

    func newGame() {
        frontend.newGame()
    }

    func restartGame() {
        frontend.restart()
    }

    func solve() {
        frontend.solve()
    }

    func presetMenu() -> [PuzzleMenuEntry] {
        frontend.menu()
    }

    func selectedPreset() -> Int {
        frontend.currentPresetId()
    }

    func updateGameType(to preset: PuzzleMenuPreset) {
        frontend.apply(preset)
    }
}
