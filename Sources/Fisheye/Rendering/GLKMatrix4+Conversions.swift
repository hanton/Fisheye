//
//  GLKMatrix4+Conversions.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import GLKit

extension GLKMatrix4 {
    /// Converts the matrix to an array of 16 float values.
    public var array: [Float] {
        return (0..<16).map { i in
            self[i]
        }
    }
}
