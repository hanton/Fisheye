//
//  FisheyeSwiftUIView.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/25/26.
//

import SwiftUI

/// A SwiftUI wrapper for FisheyeView that displays 360-degree video content.
///
/// FisheyeSwiftUIView provides a SwiftUI-native interface for the Metal-based FisheyeView,
/// with support for declarative configuration, playback control bindings, and proper resource cleanup.
///
/// Example usage:
/// ```swift
/// // Basic usage with automatic playback
/// FisheyeSwiftUIView(videoURL: videoURL)
///
/// // With playback control binding
/// @State private var isPlaying = true
/// FisheyeSwiftUIView(videoURL: videoURL, isPlaying: $isPlaying)
///
/// // With custom configuration
/// FisheyeSwiftUIView(
///     videoURL: videoURL,
///     configuration: FisheyeConfiguration(fieldOfView: 75, touchSensitivity: 0.01)
/// )
/// ```
public struct FisheyeSwiftUIView: UIViewRepresentable {
    let videoURL: URL
    var configuration: FisheyeConfiguration
    let autoPlay: Bool
    @Binding private var isPlayingBinding: Bool
    var onPlaybackFinished: (() -> Void)?

    private let useBinding: Bool

    /// Creates a new FisheyeSwiftUIView.
    ///
    /// - Parameters:
    ///   - videoURL: The URL of the 360-degree video to display.
    ///   - configuration: The configuration for video playback. Defaults to `.default`.
    ///   - autoPlay: Whether to automatically start playback. Defaults to `true`.
    ///   - isPlaying: Optional binding for controlling playback state. When provided,
    ///                the view will synchronize its playback state with this binding.
    public init(
        videoURL: URL,
        configuration: FisheyeConfiguration = .default,
        autoPlay: Bool = true,
        isPlaying: Binding<Bool>? = nil
    ) {
        self.videoURL = videoURL
        self.configuration = configuration
        self.autoPlay = autoPlay

        // Handle optional binding with a flag to track if we should use it
        if let isPlaying = isPlaying {
            self._isPlayingBinding = isPlaying
            self.useBinding = true
        } else {
            self._isPlayingBinding = .constant(true)
            self.useBinding = false
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(useBinding: useBinding)
    }

    public func makeUIView(context: Context) -> FisheyeView {
        let view = FisheyeView(frame: .zero, configuration: configuration)
        view.loadVideo(url: videoURL)

        if autoPlay {
            view.play()
            if useBinding {
                DispatchQueue.main.async {
                    self.isPlayingBinding = true
                }
            }
        } else {
            if useBinding {
                DispatchQueue.main.async {
                    self.isPlayingBinding = false
                }
            }
        }

        context.coordinator.fisheyeView = view

        return view
    }

    public func updateUIView(_ uiView: FisheyeView, context: Context) {
        // Synchronize binding state with actual playback state
        if useBinding {
            let shouldBePlaying = isPlayingBinding
            let isCurrentlyPlaying = uiView.isPlaying

            if shouldBePlaying && !isCurrentlyPlaying {
                uiView.play()
            } else if !shouldBePlaying && isCurrentlyPlaying {
                uiView.pause()
            }
        }
    }

    public static func dismantleUIView(_ uiView: FisheyeView, coordinator: Coordinator) {
        coordinator.cleanup()
        uiView.stop()
    }

    /// Coordinator for managing state between SwiftUI and UIKit.
    public class Coordinator {
        weak var fisheyeView: FisheyeView?
        let useBinding: Bool

        init(useBinding: Bool) {
            self.useBinding = useBinding
        }

        func cleanup() {
            fisheyeView = nil
        }
    }
}
