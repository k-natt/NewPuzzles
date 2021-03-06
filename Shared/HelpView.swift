//
//  HelpView.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI

struct HelpView: View {
    let url: URL

    @StateObject var navigator: WebViewNavigator

    @Environment(\.dismiss) var dismiss

    init(url: URL) {
        self.url = url
        _navigator = StateObject(wrappedValue: WebViewNavigator(initialURL: url))
    }

    var body: some View {
        NavigationView {
            WebView(navigator: navigator)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Button("Done", role: .cancel) {
                            dismiss.callAsFunction()
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            navigator.goBack()
                        } label: {
                            Label("Back", systemImage: "chevron.backward")
                        }
                        .disabled(!navigator.canGoBackward)
                        Button {
                            navigator.goForward()
                        } label: {
                            Label("Forward", systemImage: "chevron.forward")
                        }
                        .disabled(!navigator.canGoForward)
                    }
                }
                .onAppear {
                    navigator.initialLoadIfNeeded()
                }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(url: Bundle.main.url(forResource: Puzzle.allPuzzles.first?.helpName, withExtension: "html")!)
    }
}
