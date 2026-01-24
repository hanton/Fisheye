import Testing
@testable import Fisheye

@Test func fisheyeVersion() async throws {
    #expect(Fisheye.version == "1.0.0")
}

@Test func fisheyeInitialization() async throws {
    let fisheye = Fisheye()
    #expect(fisheye != nil)
}
