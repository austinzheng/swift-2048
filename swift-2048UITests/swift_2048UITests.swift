//
//  swift_2048UITests.swift
//  swift-2048UITests
//
//  Created by Chris Stott on 2017-03-20.
//
//

import XCTest

class swift_2048UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCUIDevice.shared().orientation = .faceUp
        XCUIDevice.shared().orientation = .portrait
        
        let app = XCUIApplication()
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element
        element.swipeDown()
        element.swipeLeft()
        app.staticTexts["4"].swipeUp()
        element.tap()
        element.swipeDown()
        XCUIDevice.shared().orientation = .faceUp
        
    }
    
    func testSettings() {
        XCUIApplication().buttons["Settings"].tap()

        
    }
    
}
