//
//  GameList.swift
//  Shared
//
//  Created by Kevin on 12/27/21.
//

import SwiftUI

extension Puzzle: Identifiable {
    public var id: String { name }
}

struct GameList: View {
//    @AppStorage("lastPlayed") var selectedPuzzle: PuzzleWrapper?
    @Environment(\.pushPuzzle) var pushPuzzle
    @State var loadText: String = ""
    @State var presentingImport = false

    var body: some View {
        List(Puzzle.allPuzzles) { puzzle in
            NavigationLink(to: puzzle) {
                Text(puzzle.name)
            }
//            NavigationLink(value: puzzle) {
//                Text(puzzle.name)
//            }
//            Button {
//                pushPuzzle(puzzle)
////                self.selectedPuzzle = .init(puzzle: puzzle)
//            } label: {
//                Text(puzzle.name)
//            }
        }
        .puzzleDestination { puzzle in
            GameView(gameViewModel: GameViewModel(puzzle: puzzle, loadData: loadText.isEmpty ? nil : Data(loadText.utf8)))
        }
//        .navigationDestination(item: $selectedPuzzle, destination: { puzzle in
//            GameView(gameViewModel: GameViewModel(puzzle: puzzle, loadData: loadText.isEmpty ? nil : Data(loadText.utf8)))
//        })
        .navigationTitle("Puzzles")
        .toolbar {
            ToolbarItem {
                Button {
                    presentingImport = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $presentingImport) {
            if !loadText.isEmpty,
                let puzzle = GameViewModel.puzzleForSave(Data(loadText.utf8)) {
//                selectedPuzzle = GameViewModel.puzzleForSave(Data(loadText.utf8))
                pushPuzzle(puzzle)
            }
        } content: {
            TextInputScreen(title: "Paste save string", text: $loadText, placeholder: "SAVEFILE:Simon Tatham's Portable Puzzle Collection:VERSION:1:GAME:")
        }
    }
}

#Preview {
//    @Previewable @State var cachedPath: Data? = nil
//    NavigationHelper(cachedPath: $cachedPath)
}
