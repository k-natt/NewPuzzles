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
    @State var showSettings = false

    var body: some View {
        // Need to wrap in a NavigationView for the toolbar
        NavigationView {
            VStack {
                if gameViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GameCanvasWrapper(frontend: gameViewModel.frontend)
                    StatusBar(model: gameViewModel)
                    GameButtons(buttons: gameViewModel.puzzleButtons)
                }
            }
            .background(Color("default_background"))
            .toolbar {
                GameToolbar(
                    gameViewModel: gameViewModel,
                    showSettings: $showSettings,
                    showGameMenu: $showGameMenu,
                    helpURL: $helpURL
                )
            }
            .sheet(item: $helpURL) {
                HelpView(url: $0)
            }
            .onDisappear {
                gameViewModel.save()
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
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                GameSettings(model: gameViewModel, menu: gameViewModel.presetMenu())
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(role: .cancel) {
                                showSettings = false
                            } label: {
                                Label("Cancel", systemImage: "x.circle")
                            }
                        }
                    }
            }
        }
        .confirmationDialog("Game", isPresented: $showGameMenu) {
            GameMenu(model: gameViewModel)
        }
    }
}

private struct GameToolbar: ToolbarContent {
    @StateObject var gameViewModel: GameViewModel
    @Binding var showSettings: Bool
    @Binding var showGameMenu: Bool
    @Binding var helpURL: URL?

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            GameMenuButton(model: gameViewModel, showSheet: $showGameMenu)
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
                showSettings = true
            } label: {
                Label("Type", systemImage: "gearshape")
            }
        }

    }
}

private struct GameSettings: View {

    let model: GameViewModel
    let menu: [PuzzleMenuEntry]

    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(menu, id: \.identifier) {
                switch $0 {
                case let preset as PuzzleMenuPreset:
                    HStack {
                        Button(preset.title) {
                            model.updateGameType(to: preset)
                            dismiss.callAsFunction()
                        }
                        if preset.identifier == model.selectedPreset() {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                case let submenu as PuzzleMenuSubmenu:
                    NavigationLink(submenu.title) {
                        GameSettings(model: model, menu: submenu.submenu)
                    }
                default:
                    EmptyView()
                }
            }
        }
    }
}

private struct GameButtons: View {
    let buttons: [PuzzleButton]

    var body: some View {
        if buttons.isEmpty {
            EmptyView()
        } else {
//            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
            HStack(alignment: .center, spacing: 8) {
                Spacer()
                ForEach(buttons, id: \.self) { btn in
                    Button {
                        btn.action()
                    } label: {
                        Text(btn.label)
                    }
                    .padding(.vertical, 4)
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
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
    @Binding var showSheet: Bool

    var body: some View {
        Button {
            self.showSheet = true
        } label: {
            Label("Game", systemImage: "gamecontroller")
        }
    }
}

private struct GameMenu: View {
    let model: GameViewModel

    var body: some View {
        Button("New Game", role: .destructive) {
            model.newGame()
        }
//            Button("Load Game") {
//                //
//            }
//            Button("Load by Seed") {
//                //
//            }
        Button("Restart Game") {
            model.restartGame()
        }
        if (model.canSolve) {
            Button("Solve") {
                model.solve()
            }
        }
    }
}

private struct StatusBar: View {

    @ObservedObject var model: GameViewModel

    var body: some View {
        if model.wantsStatusBar {
            Text(model.statusText ?? " ")
                .padding(8.0)
                .frame(height: 40)
                .foregroundColor(Color("text"))
        } else {
            EmptyView()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GameView(gameViewModel: GameViewModel.foreverALoad())
        }
        NavigationView {
            GameView(gameViewModel: GameViewModel(puzzle: Puzzle.allPuzzles.first!))
        }
    }
}
