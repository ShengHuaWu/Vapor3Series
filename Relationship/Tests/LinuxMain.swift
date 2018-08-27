import XCTest
@testable import AppTests

XCTMain([
  testCase(UserTests.allTests),
  testCase(PetTests.allTests)
])
