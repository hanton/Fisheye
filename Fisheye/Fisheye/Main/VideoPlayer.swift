//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import AVFoundation
import CoreVideo
import Foundation

class VideoPlayer {
    private var avPlayer: AVPlayer!
    private var avPlayerItem: AVPlayerItem!
    private var avAsset: AVAsset!
    private var output: AVPlayerItemVideoOutput!

    init(url: URL, framesPerSecond: Int) {
        avAsset = AVAsset(url: url)
        avPlayerItem = AVPlayerItem(asset: avAsset)
        avPlayer = AVPlayer(playerItem: avPlayerItem)

        configureOutput(framesPerSecond: framesPerSecond)

        NotificationCenter.default.addObserver(self, selector: #selector(playEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func play() {
        avPlayer.play()
    }

    func retrievePixelBuffer() -> CVPixelBuffer? {
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
        avPlayer.seek(to: CMTime.zero)
        avPlayer.play()
    }
}
