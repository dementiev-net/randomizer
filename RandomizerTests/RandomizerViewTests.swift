import XCTest
@testable import RandomizerCore

@MainActor
final class RandomizerViewTests: XCTestCase {
    func testTickIncrementsSessionAndAllTime() {
        let defaults = makeCleanDefaults()
        let viewModel = RandomizerView(service: MockRandomizerService(), autoStartTimer: false, defaults: defaults)

        XCTAssertEqual(viewModel.state.sessionDuration, 0)
        XCTAssertEqual(viewModel.state.allTimeDuration, 0)

        viewModel.tick()

        XCTAssertEqual(viewModel.state.sessionDuration, 1)
        XCTAssertEqual(viewModel.state.allTimeDuration, 1)
    }

    func testTickAutoGeneratesEveryTenSeconds() {
        let service = MockRandomizerService(numbers: [10, 42])
        let viewModel = RandomizerView(service: service, autoStartTimer: false, defaults: makeCleanDefaults())

        XCTAssertEqual(service.generateCallCount, 1)

        for _ in 0..<9 {
            viewModel.tick()
        }
        XCTAssertEqual(service.generateCallCount, 1)

        viewModel.tick()
        XCTAssertEqual(service.generateCallCount, 2)
    }

    func testResetSessionResetsOnlySessionDuration() {
        let viewModel = RandomizerView(service: MockRandomizerService(), autoStartTimer: false, defaults: makeCleanDefaults())

        for _ in 0..<5 {
            viewModel.tick()
        }

        XCTAssertEqual(viewModel.state.sessionDuration, 5)
        XCTAssertEqual(viewModel.state.allTimeDuration, 5)

        viewModel.resetSession()

        XCTAssertEqual(viewModel.state.sessionDuration, 0)
        XCTAssertEqual(viewModel.state.allTimeDuration, 5)
    }

    func testAllTimeDurationPersistsBetweenViewModelInstances() {
        let suite = "RandomizerTests.Persistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)

        do {
            let viewModel = RandomizerView(service: MockRandomizerService(), autoStartTimer: false, defaults: defaults)
            for _ in 0..<3 {
                viewModel.tick()
            }
            XCTAssertEqual(viewModel.state.allTimeDuration, 3)
        }

        let reloaded = RandomizerView(service: MockRandomizerService(), autoStartTimer: false, defaults: defaults)
        XCTAssertEqual(reloaded.state.allTimeDuration, 3)

        defaults.removePersistentDomain(forName: suite)
    }

    private func makeCleanDefaults() -> UserDefaults {
        let suite = "RandomizerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            fatalError("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}

private final class MockRandomizerService: RandomizerServiceProtocol {
    private var numbers: [Int]
    private var index = 0

    private(set) var generateCallCount = 0

    init(numbers: [Int] = [50]) {
        self.numbers = numbers
    }

    func generateNumber() -> Int {
        generateCallCount += 1

        let value = numbers[index % numbers.count]
        index += 1

        return value
    }

    func calculateRating(for number: Int) -> Int {
        switch number {
        case 75...: return 5
        case 66...: return 4
        case 50...: return 3
        case 33...: return 2
        case 25...: return 1
        default: return 0
        }
    }
}
