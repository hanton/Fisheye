import SwiftUI
import Fisheye

struct ContentView: View {
    var body: some View {
        if let videoURL = Bundle.main.url(forResource: "demo", withExtension: "m4v") {
            FisheyeSwiftUIView(videoURL: videoURL)
                .ignoresSafeArea()
        } else {
            Text("Error: demo.m4v not found")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    ContentView()
}
