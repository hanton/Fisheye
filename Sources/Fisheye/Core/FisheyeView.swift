//
//  FisheyeView.swift
//  Fisheye
//
//  A UIView subclass for displaying 360-degree video content.
//

import GLKit
import UIKit

/// A view that displays 360-degree video content with touch-based rotation.
public class FisheyeView: GLKView {
    /// The configuration for video playback.
    public let configuration: FisheyeConfiguration

    /// Whether the video is currently playing.
    public var isPlaying: Bool {
        return videoPlayer?.isPlaying ?? false
    }

    private var renderer: Renderer?
    private var videoPlayer: VideoPlayer?
    private var displayLink: CADisplayLink?

    private var rotationX: Float = 0.0
    private var rotationY: Float = 0.0

    /// Creates a new FisheyeView with the specified frame and configuration.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view.
    ///   - configuration: The configuration options. Defaults to `.default`.
    public init(frame: CGRect, configuration: FisheyeConfiguration = .default) {
        self.configuration = configuration
        let glContext = EAGLContext(api: .openGLES3)!
        super.init(frame: frame, context: glContext)
        setupOpenGL(context: glContext)
    }

    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        if let glContext = EAGLContext(api: .openGLES3) {
            self.context = glContext
            setupOpenGL(context: glContext)
        }
    }

    deinit {
        stopDisplayLink()
    }

    private func setupOpenGL(context glContext: EAGLContext) {
        EAGLContext.setCurrent(glContext)
        self.drawableColorFormat = .RGBA8888
        self.drawableDepthFormat = .format24

        let shader = Shader()
        let model = Sphere(sliceCount: configuration.sphereSlices)
        renderer = Renderer(context: glContext, shader: shader, model: model, fieldOfView: configuration.fieldOfView)
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
        startDisplayLink()
    }

    /// Pauses video playback.
    public func pause() {
        videoPlayer?.pause()
        stopDisplayLink()
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

    // MARK: - Display Link

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: Float(configuration.framesPerSecond), preferred: Float(configuration.framesPerSecond))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkDidFire() {
        setNeedsDisplay()
    }

    // MARK: - Drawing

    public override func draw(_ rect: CGRect) {
        guard let pixelBuffer = videoPlayer?.retrievePixelBuffer() else { return }
        renderer?.updateTexture(pixelBuffer)
        renderer?.updateModelViewProjectionMatrix(rotationX, rotationY)
        renderer?.render()
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
