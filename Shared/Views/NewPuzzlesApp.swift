//
//  NewPuzzlesApp.swift
//  Shared
//
//  Created by Kevin on 12/27/21.
//

import SwiftUI

@main
struct NewPuzzlesApp: App {
    init() {
        let textColor = UIColor(resource: .text)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: textColor
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: textColor
        ]
    }

    @AppStorage("NavPath") var cachedPath: Data?

    var body: some Scene {
        WindowGroup {
//            NavigationHelper(cachedPath: $cachedPath)
            NavigationHelper()
        }
    }
}
