//
//  Sphere.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

/// A sphere model used for 360-degree video rendering.
public class Sphere {
    /// Vertex positions for the sphere mesh.
    public let vertices: [Float]
    /// Texture coordinates for mapping video onto the sphere.
    public let texCoords: [Float]
    /// Triangle indices for rendering.
    public let indices: [UInt16]
    /// Number of vertices in the mesh.
    public let vertexCount: Int
    /// Number of indices in the mesh.
    public let indexCount: Int

    /// Creates a new sphere with the specified parameters.
    ///
    /// - Parameters:
    ///   - sliceCount: Number of slices for the sphere geometry. Default is 200.
    ///   - radius: Radius of the sphere. Default is 1.0.
    public init(sliceCount: Int = 200, radius: Float = 1.0) {
        let geometry = SphereGenerator.generate(numSlices: sliceCount, radius: radius)
        self.vertices = geometry.vertices
        self.texCoords = geometry.texCoords
        self.indices = geometry.indices
        self.vertexCount = geometry.vertexCount
        self.indexCount = geometry.indexCount
    }
}
