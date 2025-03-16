//
//  SunlightActivityAttributes.swift
//  sunny
//
//  Created by William Lu on 3/15/25.
//


import ActivityKit
import Foundation

public struct SunlightActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var elapsedSeconds: Int
        public var luxShort: Int
        public init(elapsedSeconds: Int, luxShort: Int) {
            self.elapsedSeconds = elapsedSeconds
            self.luxShort = luxShort
        }
    }
    // Optionally init
    public init() { }
}
