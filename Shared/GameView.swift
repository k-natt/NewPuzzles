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
    @State var frontend: PuzzleFrontend
//    @StateObject var gameViewModel: GameViewModel()

    @State var helpURL: URL? = nil
    @State var showGameMenu = false

    var body: some View {
        VStack {
            GameCanvasWrapper(frontend: frontend)
            if frontend.wantsStatusBar {
                Text("Status updates TBD")
            }
            if (!frontend.buttons.isEmpty) {
                HStack {
                    Spacer()
                    ForEach(frontend.buttons, id: \.self) { btn in
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
            .navigationTitle(frontend.puzzle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let helpURL = frontend.puzzle.helpURL {
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
                    Button {
                        self.showGameMenu = true
                    } label: {
                        Label("Game", systemImage: "gamecontroller")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        //
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    Button {
                        //
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
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
            .confirmationDialog("", isPresented: $showGameMenu) {
                Button(role: .destructive) {
                    //
                } label: {
                    Label("New Game", systemImage: "play")
                }
                Button {
                    //
                } label: {
                    Label("Load Game", systemImage: "square.and.arrow.down")
                }
                Button {
                    //
                } label: {
                    Label("Load by Seed", systemImage: "square.and.arrow.down.fill")
                }
                Button {
                    //
                } label: {
                    Label("Restart Game", systemImage: "restart")
                }
                Button {
                    //
                } label: {
                    Label("Solve", systemImage: "rays")
                }
                Button {
                    // NOTE: This overlaps with the bar button item, pick one.
                } label: {
                    Label("Game Settings", systemImage: "gear")
                }
            }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(frontend: PuzzleFrontend(for: Puzzle.allPuzzles.first!))
    }
}
