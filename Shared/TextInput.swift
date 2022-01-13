//
//  TextInput.swift
//  NewPuzzles
//
//  Created by Kevin on 1/9/22.
//

import Foundation
import SwiftUI

struct TextInputScreen: View {
    @State var title: String
    @Binding var text: String
    @State var placeholder: String

    var body: some View {
        List {
            Section(title) {

            }
            TextField(title, text: $text, prompt: Text(placeholder))
        }
    }
}

struct TextInputScreen_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        TextInputScreen(title: "Title", text: $text, placeholder: "SAVEFILE:Simon Tatham's Portable Puzzle Collection:VERSION:1:GAME:")
    }
}
