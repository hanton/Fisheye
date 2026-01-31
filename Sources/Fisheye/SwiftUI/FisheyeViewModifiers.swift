//
//  FisheyeViewModifiers.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/25/26.
//

import SwiftUI

// MARK: - Sphere Quality

/// Quality presets for sphere geometry detail.
///
/// Higher quality values produce smoother sphere geometry at the cost of more vertices.
public enum SphereQuality {
    case low
    case medium
    case high
    case ultra

    /// The number of slices for the sphere geometry.
    public var sliceCount: Int {
        switch self {
        case .low: return 50
        case .medium: return 100
        case .high: return 200
        case .ultra: return 400
        }
    }
}

// MARK: - View Modifiers

extension FisheyeSwiftUIView {
    /// Sets the field of view for the camera.
    ///
    /// - Parameter degrees: The field of view in degrees. Typical values range from 30 to 120.
    /// - Returns: A modified view with the specified field of view.
    public func fieldOfView(_ degrees: Float) -> Self {
        var view = self
        view.configuration.fieldOfView = degrees
        return view
    }

    /// Sets the touch sensitivity for rotation.
    ///
    /// - Parameter sensitivity: The sensitivity multiplier. Higher values make rotation more responsive.
    ///                         Default is 0.005. Typical range is 0.001 to 0.02.
    /// - Returns: A modified view with the specified touch sensitivity.
    public func touchSensitivity(_ sensitivity: Float) -> Self {
        var view = self
        view.configuration.touchSensitivity = sensitivity
        return view
    }

    /// Sets the quality of the sphere geometry.
    ///
    /// - Parameter quality: The quality preset determining sphere detail level.
    /// - Returns: A modified view with the specified sphere quality.
    public func sphereQuality(_ quality: SphereQuality) -> Self {
        var view = self
        view.configuration.sphereSlices = quality.sliceCount
        return view
    }

    /// Sets whether video playback should loop.
    ///
    /// - Parameter enabled: Whether to enable loop playback.
    /// - Returns: A modified view with the specified loop playback setting.
    public func loopPlayback(_ enabled: Bool) -> Self {
        var view = self
        view.configuration.loopPlayback = enabled
        return view
    }

    /// Sets the target frames per second for rendering.
    ///
    /// - Parameter fps: The target frames per second. Common values are 30, 60, or 120.
    /// - Returns: A modified view with the specified frame rate.
    public func framesPerSecond(_ fps: Int) -> Self {
        var view = self
        view.configuration.framesPerSecond = fps
        return view
    }

    /// Sets a callback to be executed when video playback finishes.
    ///
    /// Note: This callback is only triggered when loop playback is disabled.
    ///
    /// - Parameter action: The closure to execute when playback finishes.
    /// - Returns: A modified view with the specified callback.
    public func onPlaybackFinished(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onPlaybackFinished = action
        return view
    }
}
