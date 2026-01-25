//
//  VideoViewController.swift
//  DemoApp
//
//  Created by Hanton Yang on 2/6/23.
//

import Fisheye
import UIKit

class VideoViewController: UIViewController {
    private var fisheyeView: FisheyeView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create FisheyeView with default configuration
        fisheyeView = FisheyeView(frame: view.bounds, configuration: .default)
        fisheyeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(fisheyeView)

        // Load and play the demo video
        if let videoURL = Bundle.main.url(forResource: "demo", withExtension: "m4v") {
            fisheyeView.loadVideo(url: videoURL)
            fisheyeView.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fisheyeView.pause()
    }
}
