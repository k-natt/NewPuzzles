//
//  GameView.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI


extension URL: Identifiable {
    public var id: URL { self }
}

struct GameView: View {
    @StateObject var gameViewModel: GameViewModel

    @State var helpURL: URL? = nil
    @State var showGameMenu = false

    var body: some View {
        VStack {
            GameCanvasWrapper(frontend: gameViewModel.frontend)
            StatusBar(text: gameViewModel.statusText)
            if (!gameViewModel.puzzleButtons.isEmpty) {
                HStack {
                    Spacer()
                    ForEach(gameViewModel.puzzleButtons, id: \.self) { btn in
                        Button {
                            btn.action()
                        } label: {
                            Text(btn.label)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(gameViewModel.puzzleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let helpURL = gameViewModel.puzzleHelpURL {
                    Button {
                        self.helpURL = helpURL
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                } else {
                    EmptyView()
                }
            }
            ToolbarItem(placement: .bottomBar) {
                GameMenuButton(model: gameViewModel)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    gameViewModel.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!gameViewModel.canUndo)
                Button {
                    gameViewModel.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!gameViewModel.canRedo)
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    //
                } label: {
                    Label("Type", systemImage: "gearshape")
                }
            }
        }
        .sheet(item: $helpURL) {
            HelpView(url: $0)
        }
    }
}

private enum GameMenuResult {
    case confirmNew
    case load
    case seed
    case settings
}

private struct GameMenuButton: View {
    let model: GameViewModel

    @State var showSheet = false

//    @State var sheetResult: GameMenuResult?

    var body: some View {
        Button {
            self.showSheet = true
        } label: {
            Label("Game", systemImage: "gamecontroller")
        }
        .confirmationDialog("Game", isPresented: $showSheet) {
            Button("New Game", role: .destructive) {
                model.newGame()
            }
            Button("Load Game") {
                //
            }
            Button("Load by Seed") {
                //
            }
            Button("Restart Game") {
                model.restartGame()
            }
            if (model.canSolve) {
                Button("Solve") {
                    model.solve()
                }
            }
            Button("Game Settings") {
                // NOTE: This overlaps with the bar button item, pick one.
            }
        }
    }
}

private struct StatusBar: View {
    let text: String?

    var body: some View {
        if let text = text {
            Text(text)
                .padding(8.0)
        } else {
            EmptyView()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(gameViewModel: GameViewModel(puzzle: Puzzle.allPuzzles.first!))
    }
}
