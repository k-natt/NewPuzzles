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

extension Puzzle: RawRepresentable {
    public var rawValue: String { name }
}

struct GameList: View {
    @AppStorage("lastPlayed") var selectedPuzzle: Puzzle?
    @State var loadText: String = ""
    @State var presentingImport = false

    init() {
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(named: "text")!
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "text")!
        ]
    }
    var body: some View {
        NavigationView {
            List(Puzzle.allPuzzles, selection: $selectedPuzzle) { puzzle in
                NavigationLink(tag: puzzle, selection: $selectedPuzzle) {
                    GameView(gameViewModel: GameViewModel(puzzle: puzzle, loadData: loadText.isEmpty ? nil : Data(loadText.utf8)))
                } label: {
                    Text(puzzle.name)
                        .foregroundColor(Color("text"))
                }
            }
            .navigationTitle("Puzzles")
            .toolbar {
                ToolbarItem {
                    Button {
                        presentingImport = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .sheet(isPresented: $presentingImport) {
                        if !loadText.isEmpty {
                            selectedPuzzle = GameViewModel.puzzleForSave(Data(loadText.utf8))
                        }
                    } content: {
                        TextInputScreen(title: "Paste save string", text: $loadText, placeholder: "SAVEFILE:Simon Tatham's Portable Puzzle Collection:VERSION:1:GAME:")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameList()
    }
}
