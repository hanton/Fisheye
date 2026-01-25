//
//  VideoPlayer.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import AVFoundation
import CoreVideo
import Foundation

/// Handles video playback and frame extraction for 360-degree video rendering.
@MainActor
public class VideoPlayer {
    private var avPlayer: AVPlayer!
    private var avPlayerItem: AVPlayerItem!
    private var avAsset: AVAsset!
    private var output: AVPlayerItemVideoOutput!

    /// Whether loop playback is enabled.
    public var loopPlayback: Bool = true

    /// Whether the video is currently playing.
    public private(set) var isPlaying: Bool = false

    /// Creates a video player for the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the video file.
    ///   - framesPerSecond: The target frame rate for pixel buffer extraction.
    public init(url: URL, framesPerSecond: Int) {
        avAsset = AVAsset(url: url)
        avPlayerItem = AVPlayerItem(asset: avAsset)
        avPlayer = AVPlayer(playerItem: avPlayerItem)

        configureOutput(framesPerSecond: framesPerSecond)

        NotificationCenter.default.addObserver(self, selector: #selector(playEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Starts or resumes video playback.
    public func play() {
        avPlayer.play()
        isPlaying = true
    }

    /// Pauses video playback.
    public func pause() {
        avPlayer.pause()
        isPlaying = false
    }

    /// Retrieves the current video frame as a pixel buffer.
    ///
    /// - Returns: The current frame as a CVPixelBuffer, or nil if not available.
    public func retrievePixelBuffer() -> CVPixelBuffer? {
        let pixelBuffer = output.copyPixelBuffer(forItemTime: avPlayerItem.currentTime(), itemTimeForDisplay: nil)
        return pixelBuffer
    }

    private func configureOutput(framesPerSecond: Int) {
        let pixelBuffer = [kCVPixelBufferPixelFormatTypeKey as String:
            NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)]
        output = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBuffer)
        output.requestNotificationOfMediaDataChange(withAdvanceInterval: 1.0 / TimeInterval(framesPerSecond))
        avPlayerItem.add(output)
    }

    @objc private func playEnd() {
        if loopPlayback {
            avPlayer.seek(to: CMTime.zero)
            avPlayer.play()
        } else {
            isPlaying = false
        }
    }
}
