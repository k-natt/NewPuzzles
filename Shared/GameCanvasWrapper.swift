//
//  GameCanvasWrapper.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI

struct GameCanvasWrapper: UIViewRepresentable {
    let frontend: PuzzleFrontend

    func updateUIView(_ uiView: UIViewType, context: Context) {
        frontend.redraw()
    }

    func makeUIView(context: Context) -> some UIView {
        frontend.canvas
    }
}
