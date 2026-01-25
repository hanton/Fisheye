//
//  FisheyeConfiguration.swift
//  Fisheye
//
//  Configuration options for FisheyeView.
//

import Foundation

/// Configuration options for 360-degree video playback.
public struct FisheyeConfiguration: Sendable {
    /// Field of view in degrees. Default is 60.
    public var fieldOfView: Float

    /// Target frames per second for video playback. Default is 60.
    public var framesPerSecond: Int

    /// Number of slices for the sphere geometry. Higher values = smoother sphere. Default is 200.
    public var sphereSlices: Int

    /// Touch sensitivity for rotation. Higher values = more sensitive. Default is 0.005.
    public var touchSensitivity: Float

    /// Whether to loop video playback. Default is true.
    public var loopPlayback: Bool

    /// Creates a configuration with default values.
    public init(
        fieldOfView: Float = 60.0,
        framesPerSecond: Int = 60,
        sphereSlices: Int = 200,
        touchSensitivity: Float = 0.005,
        loopPlayback: Bool = true
    ) {
        self.fieldOfView = fieldOfView
        self.framesPerSecond = framesPerSecond
        self.sphereSlices = sphereSlices
        self.touchSensitivity = touchSensitivity
        self.loopPlayback = loopPlayback
    }

    /// Default configuration.
    public static let `default` = FisheyeConfiguration()
}
