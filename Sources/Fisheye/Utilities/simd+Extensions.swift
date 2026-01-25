//
//  simd+Extensions.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/24/26.
//
//  Matrix math helpers for Metal rendering.
//

import simd

extension simd_float4x4 {
    /// Creates a perspective projection matrix.
    ///
    /// Matches GLKMatrix4MakePerspective behavior exactly.
    ///
    /// - Parameters:
    ///   - fovY: Field of view in radians (vertical).
    ///   - aspect: Aspect ratio (width / height).
    ///   - nearZ: Near clipping plane distance.
    ///   - farZ: Far clipping plane distance.
    /// - Returns: Perspective projection matrix.
    static func perspectiveProjection(fovY: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let yScale = 1.0 / tan(fovY * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2.0 * farZ * nearZ / zRange

        return simd_float4x4(
            simd_float4(xScale, 0, 0, 0),
            simd_float4(0, yScale, 0, 0),
            simd_float4(0, 0, zScale, -1),
            simd_float4(0, 0, wzScale, 0)
        )
    }

    /// Creates a rotation matrix around the X axis.
    ///
    /// Matches GLKMatrix4RotateX behavior exactly.
    ///
    /// - Parameter angle: Rotation angle in radians.
    /// - Returns: Rotation matrix.
    static func rotationX(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return simd_float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, c, s, 0),
            simd_float4(0, -s, c, 0),
            simd_float4(0, 0, 0, 1)
        )
    }

    /// Creates a rotation matrix around the Y axis.
    ///
    /// Matches GLKMatrix4RotateY behavior exactly.
    ///
    /// - Parameter angle: Rotation angle in radians.
    /// - Returns: Rotation matrix.
    static func rotationY(_ angle: Float) -> simd_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return simd_float4x4(
            simd_float4(c, 0, -s, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(s, 0, c, 0),
            simd_float4(0, 0, 0, 1)
        )
    }

    /// Converts degrees to radians.
    ///
    /// - Parameter degrees: Angle in degrees.
    /// - Returns: Angle in radians.
    static func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180.0
    }
}
