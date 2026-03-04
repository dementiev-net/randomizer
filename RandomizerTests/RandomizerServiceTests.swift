import XCTest
@testable import RandomizerCore

@MainActor
final class RandomizerServiceTests: XCTestCase {
    func testGenerateNumberReturnsValueInExpectedRange() {
        let service = RandomizerService()

        for _ in 0..<2_000 {
            let value = service.generateNumber()
            XCTAssertGreaterThanOrEqual(value, 1)
            XCTAssertLessThanOrEqual(value, 99)
        }
    }

    func testCalculateRatingRespectsBoundaries() {
        let service = RandomizerService()

        XCTAssertEqual(service.calculateRating(for: 1), 0)
        XCTAssertEqual(service.calculateRating(for: 24), 0)

        XCTAssertEqual(service.calculateRating(for: 25), 1)
        XCTAssertEqual(service.calculateRating(for: 32), 1)

        XCTAssertEqual(service.calculateRating(for: 33), 2)
        XCTAssertEqual(service.calculateRating(for: 49), 2)

        XCTAssertEqual(service.calculateRating(for: 50), 3)
        XCTAssertEqual(service.calculateRating(for: 65), 3)

        XCTAssertEqual(service.calculateRating(for: 66), 4)
        XCTAssertEqual(service.calculateRating(for: 74), 4)

        XCTAssertEqual(service.calculateRating(for: 75), 5)
        XCTAssertEqual(service.calculateRating(for: 99), 5)
    }
}
