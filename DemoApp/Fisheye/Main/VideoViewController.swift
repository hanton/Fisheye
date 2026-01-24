//
//  ViewController.swift
//  Fisheye
//
//  Created by Hanton Yang on 2/6/23.
//

import GLKit
import UIKit

class VideoViewController: GLKViewController {
    var renderer: Renderer?
    var videoPlayer: VideoPlayer?

    private var rotationX: Float = 0.0
    private var rotationY: Float = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupRenderer()
        setupVideoPlayer()
        delegate = self
    }

    private func setupRenderer() {
        if let context = EAGLContext(api: .openGLES3) {
            EAGLContext.setCurrent(context)
            let glkView = view as! GLKView
            glkView.context = context
            let shader = Shader()
            let model = Sphere()
            renderer = Renderer(context: context, shader: shader, model: model)
        }
    }

    private func setupVideoPlayer() {
        if let path = Bundle.main.path(forResource: "demo", ofType: "m4v") {
            let url = URL(fileURLWithPath: path)
            videoPlayer = VideoPlayer(url: url, framesPerSecond: framesPerSecond)
            videoPlayer?.play()
        }
    }

    override func glkView(_: GLKView, drawIn _: CGRect) {
        // Retrieve the video pixel buffer
        guard let pixelBufer = videoPlayer?.retrievePixelBuffer() else { return }
        // Update the OpenGL ES texture by using the current video pixel buffer
        renderer?.updateTexture(pixelBufer)
        renderer?.render()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        let radiansPerPoint: Float = 0.005
        let touch = touches.first!
        let location = touch.location(in: touch.view)
        let previousLocation = touch.previousLocation(in: touch.view)
        var diffX = Float(location.x - previousLocation.x)
        var diffY = Float(location.y - previousLocation.y)

        diffX *= -radiansPerPoint
        diffY *= -radiansPerPoint
        rotationX += diffY
        rotationY += diffX
    }
}

// MARK: - GLKViewControllerDelegate

extension VideoViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_: GLKViewController) {
        // Update the model view projection matrix
        renderer?.updateModelViewProjectionMatrix(rotationX, rotationY)
    }
}
