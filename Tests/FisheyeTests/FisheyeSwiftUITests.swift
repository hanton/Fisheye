//
//  FisheyeSwiftUITests.swift
//  Fisheye
//
//  Created by Hanton Yang on 1/25/26.
//

import Testing
import SwiftUI
@testable import Fisheye

@Suite("FisheyeSwiftUIView Tests")
@MainActor
struct FisheyeSwiftUITests {
    let testURL = URL(string: "file:///test.mp4")!

    @Test("Basic initialization with default parameters")
    func basicInitialization() {
        let view = FisheyeSwiftUIView(videoURL: testURL)

        #expect(view.videoURL == testURL)
        #expect(view.configuration.fieldOfView == FisheyeConfiguration.default.fieldOfView)
        #expect(view.configuration.framesPerSecond == FisheyeConfiguration.default.framesPerSecond)
        #expect(view.autoPlay == true)
    }

    @Test("Initialization with custom configuration")
    func customConfiguration() {
        let config = FisheyeConfiguration(
            fieldOfView: 75.0,
            framesPerSecond: 30,
            sphereSlices: 100,
            touchSensitivity: 0.01,
            loopPlayback: false
        )
        let view = FisheyeSwiftUIView(videoURL: testURL, configuration: config)

        #expect(view.configuration.fieldOfView == 75.0)
        #expect(view.configuration.framesPerSecond == 30)
        #expect(view.configuration.sphereSlices == 100)
        #expect(view.configuration.touchSensitivity == 0.01)
        #expect(view.configuration.loopPlayback == false)
    }

    @Test("Initialization with autoPlay disabled")
    func autoPlayDisabled() {
        let view = FisheyeSwiftUIView(videoURL: testURL, autoPlay: false)

        #expect(view.autoPlay == false)
    }

    @Test("Field of view modifier")
    func fieldOfViewModifier() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .fieldOfView(90.0)

        #expect(view.configuration.fieldOfView == 90.0)
    }

    @Test("Touch sensitivity modifier")
    func touchSensitivityModifier() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .touchSensitivity(0.02)

        #expect(view.configuration.touchSensitivity == 0.02)
    }

    @Test("Sphere quality modifier")
    func sphereQualityModifier() {
        let lowView = FisheyeSwiftUIView(videoURL: testURL)
            .sphereQuality(.low)
        #expect(lowView.configuration.sphereSlices == 50)

        let mediumView = FisheyeSwiftUIView(videoURL: testURL)
            .sphereQuality(.medium)
        #expect(mediumView.configuration.sphereSlices == 100)

        let highView = FisheyeSwiftUIView(videoURL: testURL)
            .sphereQuality(.high)
        #expect(highView.configuration.sphereSlices == 200)

        let ultraView = FisheyeSwiftUIView(videoURL: testURL)
            .sphereQuality(.ultra)
        #expect(ultraView.configuration.sphereSlices == 400)
    }

    @Test("Loop playback modifier")
    func loopPlaybackModifier() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .loopPlayback(false)

        #expect(view.configuration.loopPlayback == false)
    }

    @Test("Frames per second modifier")
    func framesPerSecondModifier() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .framesPerSecond(30)

        #expect(view.configuration.framesPerSecond == 30)
    }

    @Test("Chained modifiers")
    func chainedModifiers() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .fieldOfView(75.0)
            .touchSensitivity(0.01)
            .sphereQuality(.high)
            .loopPlayback(false)
            .framesPerSecond(30)

        #expect(view.configuration.fieldOfView == 75.0)
        #expect(view.configuration.touchSensitivity == 0.01)
        #expect(view.configuration.sphereSlices == 200)
        #expect(view.configuration.loopPlayback == false)
        #expect(view.configuration.framesPerSecond == 30)
    }

    @Test("Sphere quality enum values")
    func sphereQualityEnumValues() {
        #expect(SphereQuality.low.sliceCount == 50)
        #expect(SphereQuality.medium.sliceCount == 100)
        #expect(SphereQuality.high.sliceCount == 200)
        #expect(SphereQuality.ultra.sliceCount == 400)
    }

    @Test("OnPlaybackFinished callback is set")
    func onPlaybackFinishedCallback() {
        let view = FisheyeSwiftUIView(videoURL: testURL)
            .onPlaybackFinished { }

        #expect(view.onPlaybackFinished != nil)
    }
}
