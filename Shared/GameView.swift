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
    @State var showExportMenu = false

    var body: some View {
        // Need to wrap in a NavigationView for the toolbar
        VStack {
            if gameViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GameCanvasWrapper(frontend: gameViewModel.frontend)
                StatusBar(model: gameViewModel)
                GameButtons(buttons: gameViewModel.puzzleButtons)
                Spacer(minLength: 25)
                GameUndoRedoBar(model: gameViewModel)
                Spacer(minLength: 40)
            }
        }
        .background(Color("default_background"))
        .sheet(item: $helpURL) {
            HelpView(url: $0)
        }
        .onDisappear {
            gameViewModel.save()
        }
        .navigationTitle(gameViewModel.puzzleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                GameMenuButton(model: gameViewModel, showSheet: $showGameMenu)
            }

        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                GameSettings(model: gameViewModel, menu: gameViewModel.presetMenu())
                    .navigationTitle("Settings")
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
        .confirmationDialog("Export", isPresented: $showExportMenu) {
            Button("Copy game state") {
                UIPasteboard.general.string = gameViewModel.exportState()
            }
            Button("Copy game settings") {
                UIPasteboard.general.string = gameViewModel.exportSettings()
            }
            Button("Copy game seed") {
                UIPasteboard.general.string = gameViewModel.exportSeed()
            }
            Button("Export save file") {
                gameViewModel.shareAsFile()
            }
        }
        .confirmationDialog("Game", isPresented: $showGameMenu) {
            GameMenu(model: gameViewModel, showSettings: $showSettings, showExport: $showExportMenu, helpURL: $helpURL)
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

private struct GameUndoRedoBar: View {
    @StateObject var model: GameViewModel

    var body: some View {
        HStack {
            Spacer()
            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!model.canUndo)
            Spacer()
            Button {
                model.redo()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!model.canRedo)
            Spacer()
        }
    }
}

private struct GameButtons: View {
    let buttons: [PuzzleButton]

    var body: some View {
        if buttons.isEmpty {
            EmptyView()
        } else {
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
    @Binding var showSettings: Bool
    @Binding var showExport: Bool
    @Binding var helpURL: URL?

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
        Button {
            showSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
        Button {
            showExport = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        if let helpURL = model.puzzleHelpURL {
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

private struct StatusBar: View {

    @ObservedObject var model: GameViewModel

    var body: some View {
        if model.wantsStatusBar {
            Text(model.statusText ?? " ")
                .foregroundColor(Color("text"))
                .minimumScaleFactor(0.5)
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
