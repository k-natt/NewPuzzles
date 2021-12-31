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
    var body: some View {
        NavigationView {
            List(Puzzle.allPuzzles, selection: $selectedPuzzle) { puzzle in
                NavigationLink(tag: puzzle, selection: $selectedPuzzle) {
                    GameView(frontend: PuzzleFrontend(for: puzzle))
                } label: {
                    Text(puzzle.name)
                }
            }
            .navigationTitle("Puzzles")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GameList()
    }
}
