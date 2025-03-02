import XCTest

final class sunnyUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Possibly take screenshot or do launch verifications
        _ = app.screenshot()
    }
}