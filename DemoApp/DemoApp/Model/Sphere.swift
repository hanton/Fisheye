//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import GLKit

class Sphere {
    var vertices: UnsafeMutablePointer<GLfloat>?
    var texCoords: UnsafeMutablePointer<GLfloat>?
    var indices: UnsafeMutablePointer<GLushort>?
    var vertexCount: GLint = 0
    var indexCount: GLint = 0

    init() {
        let sliceCount: GLint = 200
        let radius: GLfloat = 1.0
        vertexCount = (sliceCount / 2 + 1) * (sliceCount + 1)
        indexCount = esGenSphere(sliceCount, radius, &vertices, &texCoords, &indices)
    }
}
