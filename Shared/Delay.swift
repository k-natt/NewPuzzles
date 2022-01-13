//
//  Delay.swift
//  NewPuzzles
//
//  Created by Kevin on 1/2/22.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(_ time: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(time * Double(NSEC_PER_SEC)))
    }
}
