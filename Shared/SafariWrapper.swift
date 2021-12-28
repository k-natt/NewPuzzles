//
//  SafariWrapper.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI
import SafariServices

struct SafariWrapper: UIViewControllerRepresentable {
    private let vc: SFSafariViewController

    init(initialURL: URL) {
        self.vc = SFSafariViewController(url: initialURL)
    }

    func makeUIViewController(context: Context) -> some UIViewController { vc }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
