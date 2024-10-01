//
//  NavigationHelper.swift
//  NewPuzzles
//
//  Created by Kevin on 9/30/24.
//

import Observation
import SwiftUI

extension EnvironmentValues {
    @Entry var pushPuzzle: (Puzzle) -> Void = {_ in}
}

extension View {
    func puzzleDestination<C: View>(@ViewBuilder destination: @escaping (Puzzle) -> C) -> some View {
        navigationDestination(for: PuzzleWrapper.self) { wrapper in
            destination(wrapper.puzzle)
        }
        .navigationDestination(for: Puzzle.self, destination: destination)
    }
}

extension NavigationLink where Destination == Never {
    nonisolated public init(to puzzle: Puzzle, @ViewBuilder label: () -> Label) {
        self.init(value: PuzzleWrapper(puzzle: puzzle)) {
            label()
        }
    }

}

@Observable
private class NavigationHandler {
    var path: NavigationPath {
        didSet {
            pathUpdated()
        }
    }

    init() {
        var restoredRepresentation: NavigationPath.CodableRepresentation?
        if let cachedPath = UserDefaults.standard.data(forKey: "path") {
            do {
                restoredRepresentation = try JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: cachedPath)
            } catch {
                print("Error restoring path: \(error)")
            }
        }
        if let restoredRepresentation {
            self.path = NavigationPath(restoredRepresentation)
        } else {
            self.path = NavigationPath()
        }
    }

    func pathUpdated() {
        print("Path changed to \(path)")
        do {
            guard let codable = path.codable else {
                print("Path not codable: \(path)")
                return
            }
            let rep = try JSONEncoder().encode(codable)
            UserDefaults.standard.set(rep, forKey: "path")
        } catch {
            print("Error encoding: \(error)")
        }

    }
}

struct NavigationHelper: View {
//    @State var path = NavigationPath()
    @State private var model: NavigationHandler = .init()

    var body: some View {
        NavigationStack(path: $model.path) {
            GameList()
                .environment(\.pushPuzzle) {
                    self.model.path.append(PuzzleWrapper(puzzle: $0))
                }
        }
    }
}

//#Preview {
//    @Previewable @State var cachedPath: Data? = nil
//    NavigationHelper(cachedPath: $cachedPath)
//}
