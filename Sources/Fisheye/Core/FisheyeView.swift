//
//  FisheyeView.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/24/26.
//
//  A UIView subclass for displaying 360-degree video content.
//

import MetalKit
import UIKit

/// A view that displays 360-degree video content with touch-based rotation.
public class FisheyeView: MTKView {
    /// The configuration for video playback.
    public let configuration: FisheyeConfiguration

    /// Whether the video is currently playing.
    public var isPlaying: Bool {
        return videoPlayer?.isPlaying ?? false
    }

    private var renderer: MetalRenderer?
    private var videoPlayer: VideoPlayer?
    private let metalDevice: MTLDevice
    private var commandQueue: MTLCommandQueue?

    private var rotationX: Float = 0.0
    private var rotationY: Float = 0.0

    /// Creates a new FisheyeView with the specified frame and configuration.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view.
    ///   - configuration: The configuration options. Defaults to `.default`.
    public init(frame: CGRect, configuration: FisheyeConfiguration = .default) {
        self.configuration = configuration
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.metalDevice = device
        super.init(frame: frame, device: device)
        setupMetal()
    }

    required init(coder: NSCoder) {
        self.configuration = .default
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.metalDevice = device
        super.init(coder: coder)
        self.device = device
        setupMetal()
    }

    private func setupMetal() {
        self.delegate = self
        self.device = metalDevice

        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        self.preferredFramesPerSecond = configuration.framesPerSecond
        self.isPaused = false
        self.enableSetNeedsDisplay = false
        self.isOpaque = true
        self.framebufferOnly = true

        guard let queue = metalDevice.makeCommandQueue() else {
            return
        }
        commandQueue = queue

        let model = Sphere(sliceCount: configuration.sphereSlices)
        renderer = MetalRenderer(device: metalDevice, model: model, fieldOfView: configuration.fieldOfView)
        renderer?.setViewportSize(bounds.size)
    }

    /// Loads a video from the specified URL.
    ///
    /// - Parameter url: The URL of the video file.
    public func loadVideo(url: URL) {
        videoPlayer = VideoPlayer(url: url, framesPerSecond: configuration.framesPerSecond)
        videoPlayer?.loopPlayback = configuration.loopPlayback
    }

    /// Starts video playback.
    public func play() {
        videoPlayer?.play()
    }

    /// Pauses video playback.
    public func pause() {
        videoPlayer?.pause()
        self.isPaused = true
    }

    /// Stops video playback and releases resources.
    public func stop() {
        pause()
        videoPlayer = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        renderer?.setViewportSize(bounds.size)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setNeedsLayout()
        }
    }

    // MARK: - Touch Handling

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        var diffX = Float(location.x - previousLocation.x)
        var diffY = Float(location.y - previousLocation.y)

        diffX *= -configuration.touchSensitivity
        diffY *= -configuration.touchSensitivity

        rotationX += diffY
        rotationY += diffX
    }
}

// MARK: - MTKViewDelegate

extension FisheyeView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer?.setViewportSize(size)
    }

    public func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }

        if let pixelBuffer = videoPlayer?.retrievePixelBuffer() {
            renderer?.updateTexture(pixelBuffer)
        }

        renderer?.updateModelViewProjectionMatrix(rotationX, rotationY)
        renderer?.render(in: view, commandBuffer: commandBuffer)

        commandBuffer.commit()
    }
}
