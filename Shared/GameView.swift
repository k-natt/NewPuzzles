//
//  GameView.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI

extension Puzzle {
    var helpURL: URL? {
        Bundle.main.url(forResource: helpName, withExtension: "html")
    }
}

extension URL: Identifiable {
    public var id: URL { self }
}

struct GameView: View {
    let puzzle: Puzzle

    @State var helpURL: URL?

    var body: some View {
        NavigationView {
            Text(puzzle.name)
                .navigationTitle(puzzle.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if let helpURL = puzzle.helpURL {
                            Button("Help") {
                                self.helpURL = helpURL
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
        }
        .sheet(item: $helpURL) {
            HelpView(url: $0)
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(puzzle: Puzzle.allPuzzles.first!)
    }
}
