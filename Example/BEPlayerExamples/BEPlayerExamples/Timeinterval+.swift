//
//  Timeinterval+.swift
//  BEPlayerExamples
//
//  Created by bluegg on 2024/12/5.
//

import Foundation

extension TimeInterval {
   
    var toHMSTime: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        let s = Int(self) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
