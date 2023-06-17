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

    @Published private(set) var puzzleButtons: [PuzzleButton]
    @Published private(set) var statusText: String?
    @Published private(set) var wantsStatusBar = false
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published private(set) var canSolve = false
    @Published private(set) var inProgress = false {
        didSet {
            if !inProgress {
                saveState = nil
            }
        }
    }

    @Published var isLoading = false

    // These will be dynamically created based on the current game.
    @AppStorage("") private var saveState: Data?
    @AppStorage("") private var preset: Int = -1
//    @AppStorage("") private var lastSelectedPreset: Int

    let puzzle: Puzzle
    let frontend: PuzzleFrontend

    static func puzzleForSave(_ data: Data) -> Puzzle? {
        do {
            return try PuzzleFrontend.identify(data)
        } catch {
            NSLog("Error identifying save string: \(error)")
            return nil
        }
    }

    init(puzzle: Puzzle, loadData: Data? = nil) {
        self._saveState = AppStorage("\(puzzle.name)-save")
        self._preset = AppStorage(wrappedValue: -1, "\(puzzle.name)-preset")
        self.puzzle = puzzle
        self.puzzleName = puzzle.name
        self.frontend = PuzzleFrontend(puzzle: puzzle)
        self.puzzleHelpURL = Bundle.main.url(forResource: puzzle.helpName, withExtension: "html")
        self.puzzleButtons = frontend.buttons

        frontend.publisher(for: \.canUndo).receive(on: DispatchQueue.main).assign(to: &$canUndo)
        frontend.publisher(for: \.canRedo).receive(on: DispatchQueue.main).assign(to: &$canRedo)
        frontend.publisher(for: \.canSolve).receive(on: DispatchQueue.main).assign(to: &$canSolve)
        frontend.publisher(for: \.inProgress).receive(on: DispatchQueue.main).assign(to: &$inProgress)
        frontend.publisher(for: \.statusText).receive(on: DispatchQueue.main).assign(to: &$statusText)
        frontend.publisher(for: \.buttons).receive(on: DispatchQueue.main).assign(to: &$puzzleButtons)
        frontend.publisher(for: \.wantsStatusBar).receive(on: DispatchQueue.main).assign(to: &$wantsStatusBar)

        NotificationCenter.default.addObserver(self, selector: #selector(save(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

        if let restoreData = loadData ?? saveState {
            do {
                try frontend.restore(restoreData)
            } catch {
                NSLog("Error restoring game data: \(error)");
                newGame()
            }
        } else if preset >= 0 {
            frontend.applyPresetId(preset)
        } else {
            newGame()
        }
    }

    @objc private func save(_ notification: NSNotification) {
        if inProgress {
            save()
        }
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
        isLoading = true
        frontend.newGame {
            self.isLoading = false
        }
    }

    func restartGame() {
        frontend.restart()
    }

    func solve() {
        do {
            try frontend.solve()
        } catch {
            NSLog("Error solving puzzle: \(error)")
        }
    }

    func presetMenu() -> [PuzzleMenuEntry] {
        frontend.menu()
    }

    func selectedPreset() -> Int {
        frontend.currentPresetId()
    }

    func updateGameType(to preset: PuzzleMenuPreset) {
        frontend.apply(preset)
        self.preset = frontend.currentPresetId()
    }

    func exportSeed() -> String? { frontend.gameSeed() }
    func exportState() -> String? { frontend.gameStateExportable() }
    func exportSettings() -> String? { frontend.gameSettingsExportable() }

    func shareAsFile() {
        guard let vc = UIApplication.shared.windows.first?.rootViewController else {
            NSLog("Failed to find root view controller")
            return
        }
        guard let saveData = frontend.save() else {
            NSLog("Failed to save game for export")
            return
        }
        let path = "\(NSTemporaryDirectory())/\(puzzle.name).save"
        do {
            try saveData.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            NSLog("Failed to write game for export: \(error)")
            return
        }
        let uav = UIActivityViewController(activityItems: [NSURL(fileURLWithPath: path)], applicationActivities: [])
        vc.present(uav, animated: true)
    }

    deinit {
        frontend.finish()
    }
}

extension GameViewModel {
    static func foreverALoad() -> GameViewModel {
        let gvm = GameViewModel(puzzle: Puzzle.allPuzzles.first!)
        gvm.isLoading = true
        return gvm
    }
}
