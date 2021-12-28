//
//  WebView.swift
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

import Foundation
import SwiftUI
import WebKit

class WebViewNavigator: NSObject, WKNavigationDelegate, ObservableObject {
    @Published var canGoForward = false
    @Published var canGoBackward = false

    private var initialURL: URL?

    fileprivate let webview = WKWebView()

    init(initialURL: URL?) {
        self.initialURL = initialURL
        super.init()
        webview.navigationDelegate = self
    }

    func initialLoadIfNeeded() {
        if let initialURL = initialURL {
            webview.load(URLRequest(url: initialURL))
            self.initialURL = nil
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        canGoForward = webView.canGoForward
        canGoBackward = webView.canGoBack
    }


    func goBack() {
        webview.goBack()
    }

    func goForward() {
        webview.goForward()
    }
}

struct WebView: UIViewRepresentable {
    let navigator: WebViewNavigator

    func makeUIView(context: Context) -> some UIView { navigator.webview }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
