# Fisheye

A 360-degree panorama video player library for iOS.

![screenshot](./Screenshot/PlayDemo.gif)

## Features

- Play 360-degree panoramic videos
- Touch-based rotation for immersive viewing
- Easy-to-use `FisheyeView` API
- Configurable field of view, frame rate, and touch sensitivity
- Pure Swift implementation (no C dependencies)

## Requirements

- iOS 15.0+
- Swift 5.0+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add Fisheye to your project using Swift Package Manager:

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/user/Fisheye`
3. Select the version you want to use
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/user/Fisheye", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import Fisheye
import UIKit

class VideoViewController: UIViewController {
    private var fisheyeView: FisheyeView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create FisheyeView
        fisheyeView = FisheyeView(frame: view.bounds)
        fisheyeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(fisheyeView)

        // Load and play a video
        if let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4") {
            fisheyeView.loadVideo(url: videoURL)
            fisheyeView.play()
        }
    }
}
```

### Custom Configuration

```swift
let config = FisheyeConfiguration(
    fieldOfView: 90.0,        // Field of view in degrees
    framesPerSecond: 30,      // Target frame rate
    sphereSlices: 100,        // Sphere geometry detail
    touchSensitivity: 0.01,   // Touch rotation sensitivity
    loopPlayback: true        // Loop video playback
)

let fisheyeView = FisheyeView(frame: view.bounds, configuration: config)
```

### Playback Control

```swift
fisheyeView.play()     // Start playback
fisheyeView.pause()    // Pause playback
fisheyeView.stop()     // Stop and release resources
fisheyeView.isPlaying  // Check playback state
```

## Example App

See the `Example/DemoApp` directory for a complete example application demonstrating how to use the Fisheye library.

To run the example:

1. Open `Example/DemoApp/DemoApp.xcodeproj` in Xcode
2. Build and run on an iOS simulator or device

## Architecture

The library is structured as follows:

```
Sources/Fisheye/
├── Fisheye.swift              # Library entry point and version
├── Core/
│   ├── FisheyeView.swift      # High-level UIView API
│   └── FisheyeConfiguration.swift
├── Rendering/
│   ├── Renderer.swift         # OpenGL ES rendering
│   ├── Shader.swift           # Shader program management
│   ├── GLProgram.swift        # Shader compilation
│   └── GLKMatrix4+Conversions.swift
├── Geometry/
│   ├── Sphere.swift           # Sphere model
│   └── SphereGenerator.swift  # Pure Swift sphere generation
├── Video/
│   └── VideoPlayer.swift      # AVFoundation video playback
└── Resources/
    ├── vertexShader.glsl
    └── fragmentShader.glsl
```

## Tutorial

For a detailed explanation of how the 360-degree video rendering works, see:
[How to Create a 360 Video Player with OpenGL ES 3.0 and GLKit in iOS](https://medium.com/@hanton.yang/how-to-create-a-360-video-player-with-opengl-es-3-0-and-glkit-360-3f29a9cfac88)

## Todo

- Metal version for modern devices

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add awesome feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Fisheye is available under the MIT license. See the LICENSE file for more info.

### Third-Party Licenses

The sphere generation algorithm is based on code from the OpenGL ES 3.0 Programming Guide:
- Copyright (c) 2013 Dan Ginsburg, Budirijanto Purnomo
- Licensed under the MIT License
