//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import GLKit

extension GLKMatrix4 {
    var array: [Float] {
        return (0 ..< 16).map { i in
            self[i]
        }
    }
}
