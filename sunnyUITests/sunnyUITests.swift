import XCTest

final class sunnyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Basic UI test: if app launches, onboarding is shown.
        XCTAssertTrue(app.staticTexts["Welcome to Sunny"].exists)
    }
}