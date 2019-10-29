//
//  CGFloat+Extension.swift
//  bodyDetection
//
//  Created by Andressa Valengo on 28/10/19.
//  Copyright © 2019 Andressa Valengo. All rights reserved.
//

import UIKit

extension CGFloat {
    func fomatted(with pattern: String = "%.3f") -> String {
        return String(format: pattern, Double(self))
    }
}
