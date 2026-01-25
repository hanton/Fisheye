//
//  FisheyeTests.swift
//  Fisheye
//

import XCTest
@testable import Fisheye

final class FisheyeTests: XCTestCase {

    func testSphereGeneratorOutput() {
        let numSlices = 10
        let radius: Float = 1.0
        let geometry = SphereGenerator.generate(numSlices: numSlices, radius: radius)

        // Verify vertex count
        let expectedVertexCount = (numSlices / 2 + 1) * (numSlices + 1)
        XCTAssertEqual(geometry.vertexCount, expectedVertexCount)
        XCTAssertEqual(geometry.vertices.count, expectedVertexCount * 3)

        // Verify texCoord count
        XCTAssertEqual(geometry.texCoords.count, expectedVertexCount * 2)

        // Verify index count
        let expectedIndexCount = (numSlices / 2) * numSlices * 6
        XCTAssertEqual(geometry.indexCount, expectedIndexCount)
        XCTAssertEqual(geometry.indices.count, expectedIndexCount)

        // Verify all indices are within bounds
        for index in geometry.indices {
            XCTAssertLessThan(Int(index), geometry.vertexCount, "Index out of bounds")
        }

        // Verify texture coordinates are in [0, 1] range
        for texCoord in geometry.texCoords {
            XCTAssertGreaterThanOrEqual(texCoord, 0.0)
            XCTAssertLessThanOrEqual(texCoord, 1.0)
        }
    }

    func testSphereGeneratorRadius() {
        let geometry = SphereGenerator.generate(numSlices: 10, radius: 2.0)

        // Find the maximum distance from origin (should be approximately the radius)
        var maxDistance: Float = 0.0
        for i in stride(from: 0, to: geometry.vertices.count, by: 3) {
            let x = geometry.vertices[i]
            let y = geometry.vertices[i + 1]
            let z = geometry.vertices[i + 2]
            let distance = sqrt(x * x + y * y + z * z)
            maxDistance = max(maxDistance, distance)
        }

        XCTAssertEqual(maxDistance, 2.0, accuracy: 0.001)
    }

    func testFisheyeConfigurationDefaults() {
        let config = FisheyeConfiguration.default

        XCTAssertEqual(config.fieldOfView, 60.0)
        XCTAssertEqual(config.framesPerSecond, 60)
        XCTAssertEqual(config.sphereSlices, 200)
        XCTAssertEqual(config.touchSensitivity, 0.005)
        XCTAssertTrue(config.loopPlayback)
    }

    func testFisheyeConfigurationCustomValues() {
        let config = FisheyeConfiguration(
            fieldOfView: 90.0,
            framesPerSecond: 30,
            sphereSlices: 100,
            touchSensitivity: 0.01,
            loopPlayback: false
        )

        XCTAssertEqual(config.fieldOfView, 90.0)
        XCTAssertEqual(config.framesPerSecond, 30)
        XCTAssertEqual(config.sphereSlices, 100)
        XCTAssertEqual(config.touchSensitivity, 0.01)
        XCTAssertFalse(config.loopPlayback)
    }

    func testSphereCreation() {
        let sphere = Sphere(sliceCount: 50, radius: 1.5)

        let expectedVertexCount = (50 / 2 + 1) * (50 + 1)
        XCTAssertEqual(sphere.vertexCount, expectedVertexCount)
        XCTAssertEqual(sphere.vertices.count, expectedVertexCount * 3)
        XCTAssertEqual(sphere.texCoords.count, expectedVertexCount * 2)
    }

    func testFisheyeVersion() {
        XCTAssertFalse(Fisheye.version.isEmpty)
    }
}
