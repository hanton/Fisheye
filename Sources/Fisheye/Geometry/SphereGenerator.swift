//
//  SphereGenerator.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/24/26.
//
//  Pure Swift port of sphere generation algorithm.
//
//  Original C implementation:
//  The MIT License (MIT)
//
//  Copyright (c) 2013 Dan Ginsburg, Budirijanto Purnomo
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Book:      OpenGL(R) ES 3.0 Programming Guide, 2nd Edition
//  Authors:   Dan Ginsburg, Budirijanto Purnomo, Dave Shreiner, Aaftab Munshi
//  ISBN-10:   0-321-93388-5
//  ISBN-13:   978-0-321-93388-1
//  Publisher: Addison-Wesley Professional
//  URLs:      http://www.opengles-book.com
//

import Foundation

/// Result of sphere geometry generation containing vertices, texture coordinates, and indices.
public struct SphereGeometry {
    /// Vertex positions as [x, y, z, x, y, z, ...] array.
    public let vertices: [Float]
    /// Texture coordinates as [u, v, u, v, ...] array.
    public let texCoords: [Float]
    /// Triangle indices for GL_TRIANGLES rendering.
    public let indices: [UInt16]
    /// Number of vertices in the geometry.
    public let vertexCount: Int
    /// Number of indices in the geometry.
    public let indexCount: Int
}

/// Generates sphere geometry for 360-degree video rendering.
public enum SphereGenerator {

    /// Generates a UV sphere with the specified number of slices and radius.
    ///
    /// - Parameters:
    ///   - numSlices: The number of vertical slices (longitude divisions). More slices = smoother sphere.
    ///   - radius: The radius of the sphere.
    /// - Returns: A `SphereGeometry` containing the generated mesh data.
    public static func generate(numSlices: Int, radius: Float) -> SphereGeometry {
        let numParallels = numSlices / 2
        let numVertices = (numParallels + 1) * (numSlices + 1)
        let numIndices = numParallels * numSlices * 6
        let angleStep = (2.0 * Float.pi) / Float(numSlices)

        var vertices = [Float](repeating: 0, count: 3 * numVertices)
        var texCoords = [Float](repeating: 0, count: 2 * numVertices)
        var indices = [UInt16](repeating: 0, count: numIndices)

        // Generate vertices and texture coordinates
        for i in 0..<(numParallels + 1) {
            for j in 0..<(numSlices + 1) {
                let vertexIndex = (i * (numSlices + 1) + j) * 3
                let texIndex = (i * (numSlices + 1) + j) * 2

                let sinI = sin(angleStep * Float(i))
                let cosI = cos(angleStep * Float(i))
                let sinJ = sin(angleStep * Float(j))
                let cosJ = cos(angleStep * Float(j))

                vertices[vertexIndex + 0] = radius * sinI * cosJ
                vertices[vertexIndex + 1] = radius * cosI
                vertices[vertexIndex + 2] = radius * sinI * sinJ

                texCoords[texIndex + 0] = Float(j) / Float(numSlices)
                texCoords[texIndex + 1] = Float(i) / Float(numParallels)
            }
        }

        // Generate indices for triangles
        var indexOffset = 0
        for i in 0..<numParallels {
            for j in 0..<numSlices {
                let topLeft = UInt16(i * (numSlices + 1) + j)
                let bottomLeft = UInt16((i + 1) * (numSlices + 1) + j)
                let bottomRight = UInt16((i + 1) * (numSlices + 1) + (j + 1))
                let topRight = UInt16(i * (numSlices + 1) + (j + 1))

                // First triangle (reversed winding for inward-facing)
                indices[indexOffset] = topLeft
                indices[indexOffset + 1] = bottomRight
                indices[indexOffset + 2] = bottomLeft

                // Second triangle (reversed winding for inward-facing)
                indices[indexOffset + 3] = topLeft
                indices[indexOffset + 4] = topRight
                indices[indexOffset + 5] = bottomRight

                indexOffset += 6
            }
        }

        return SphereGeometry(
            vertices: vertices,
            texCoords: texCoords,
            indices: indices,
            vertexCount: numVertices,
            indexCount: numIndices
        )
    }
}
