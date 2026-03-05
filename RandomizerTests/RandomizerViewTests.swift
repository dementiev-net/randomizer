import XCTest
@testable import RandomizerCore

@MainActor
final class RandomizerViewTests: XCTestCase {
    func testTickIncrementsSessionAndAllTime() {
        let defaults = makeCleanDefaults()
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        XCTAssertEqual(viewModel.state.sessionDuration, 0)
        XCTAssertEqual(viewModel.state.allTimeDuration, 0)

        viewModel.tick()

        XCTAssertEqual(viewModel.state.sessionDuration, 1)
        XCTAssertEqual(viewModel.state.allTimeDuration, 1)
    }

    func testTickAutoGeneratesEveryTenSeconds() {
        let service = MockRandomizerService(numbers: [10, 42])
        let viewModel = RandomizerView(
            service: service,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        XCTAssertEqual(service.generateCallCount, 1)

        for _ in 0..<9 {
            viewModel.tick()
        }
        XCTAssertEqual(service.generateCallCount, 1)

        viewModel.tick()
        XCTAssertEqual(service.generateCallCount, 2)
    }

    func testResetSessionResetsOnlySessionDuration() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        for _ in 0..<5 {
            viewModel.tick()
        }

        XCTAssertEqual(viewModel.state.sessionDuration, 5)
        XCTAssertEqual(viewModel.state.allTimeDuration, 5)

        viewModel.resetSession()

        XCTAssertEqual(viewModel.state.sessionDuration, 0)
        XCTAssertEqual(viewModel.state.allTimeDuration, 5)
    }

    func testAllTimeDurationPersistsBetweenViewModelInstancesWithinSameDay() {
        let suite = "RandomizerTests.Persistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_000_000))

        do {
            let viewModel = RandomizerView(
                service: MockRandomizerService(),
                autoStartTimer: false,
                defaults: defaults,
                bankrollSettingsFileURL: makeSettingsFileURL(),
                shotJournalFileURL: makeShotJournalFileURL(),
                currentDateProvider: { clock.now }
            )
            for _ in 0..<3 {
                viewModel.tick()
            }
            XCTAssertEqual(viewModel.state.allTimeDuration, 3)
        }

        let reloaded = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL(),
            currentDateProvider: { clock.now }
        )
        XCTAssertEqual(reloaded.state.allTimeDuration, 3)

        defaults.removePersistentDomain(forName: suite)
    }

    func testAllTimeDurationResetsBetweenViewModelInstancesOnNextDay() {
        let suite = "RandomizerTests.PersistenceByDay.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_000_000))

        do {
            let viewModel = RandomizerView(
                service: MockRandomizerService(),
                autoStartTimer: false,
                defaults: defaults,
                bankrollSettingsFileURL: makeSettingsFileURL(),
                shotJournalFileURL: makeShotJournalFileURL(),
                currentDateProvider: { clock.now }
            )
            for _ in 0..<3 {
                viewModel.tick()
            }
            XCTAssertEqual(viewModel.state.allTimeDuration, 3)
        }

        clock.advance(by: 86_400)

        let reloaded = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL(),
            currentDateProvider: { clock.now }
        )
        XCTAssertEqual(reloaded.state.allTimeDuration, 0)

        defaults.removePersistentDomain(forName: suite)
    }

    func testAllTimeDurationResetsAtDayBoundaryDuringTick() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        let defaults = makeCleanDefaults()
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL(),
            currentDateProvider: { clock.now }
        )

        viewModel.tick()
        viewModel.tick()
        XCTAssertEqual(viewModel.state.allTimeDuration, 2)

        clock.advance(by: 86_400)
        viewModel.tick()
        XCTAssertEqual(viewModel.state.allTimeDuration, 1)
    }

    func testFatigueTransitionSendsRestNotificationOnce() {
        let notifications = MockNotificationService()
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            notificationService: notifications,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        XCTAssertEqual(notifications.authorizationRequestsCount, 0)
        viewModel.requestNotificationAuthorization()
        XCTAssertEqual(notifications.authorizationRequestsCount, 1)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Пора отдохнуть" }.count,
            0
        )

        viewModel.state.allTimeDuration = 3_599
        viewModel.tick()
        XCTAssertEqual(viewModel.fatigueState, .warning)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Пора отдохнуть" }.count,
            1
        )

        viewModel.tick()
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Пора отдохнуть" }.count,
            1
        )
    }

    func testSessionStopLossBlocksGenerationUntilReset() {
        let service = MockRandomizerService(numbers: [11, 22, 33])
        let notifications = MockNotificationService()
        let viewModel = RandomizerView(
            service: service,
            notificationService: notifications,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setShotAttempts(10)
        viewModel.setSessionStopLossUSD(50)
        viewModel.addShotJournalEntry(resultUSD: -30, comment: "", applyToBankroll: false)
        viewModel.addShotJournalEntry(resultUSD: -20, comment: "", applyToBankroll: false)

        XCTAssertEqual(viewModel.sessionResultUSD, -50)
        XCTAssertEqual(viewModel.sessionLimitReason, .stopLoss)
        XCTAssertTrue(viewModel.isSessionPlayBlocked)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Игра запрещена по stop-loss" }.count,
            1
        )

        XCTAssertEqual(service.generateCallCount, 1)
        viewModel.generateNewData()
        XCTAssertEqual(service.generateCallCount, 1)

        viewModel.resetSession()
        XCTAssertEqual(viewModel.sessionResultUSD, 0)
        XCTAssertNil(viewModel.sessionLimitReason)
        XCTAssertFalse(viewModel.isSessionPlayBlocked)

        viewModel.generateNewData()
        XCTAssertEqual(service.generateCallCount, 2)
    }

    func testHardStopLossBreakAutoResetsSessionAfterTimeout() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_700_000_000))
        let service = MockRandomizerService(numbers: [11, 22, 33])
        let notifications = MockNotificationService()
        let viewModel = RandomizerView(
            service: service,
            notificationService: notifications,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL(),
            currentDateProvider: { clock.now }
        )

        viewModel.setShotAttempts(10)
        viewModel.setHardStopLossEnabled(true)
        viewModel.setHardStopLossBreakMinutes(1)
        viewModel.setSessionStopLossUSD(50)
        viewModel.addShotJournalEntry(resultUSD: -50, comment: "", applyToBankroll: false)

        XCTAssertEqual(viewModel.sessionLimitReason, .stopLoss)
        XCTAssertTrue(viewModel.isHardStopLossBreakActive)
        XCTAssertEqual(viewModel.hardStopLossBreakRemainingSeconds, 60)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Игра запрещена по stop-loss" }.count,
            1
        )

        let callsBeforeManualGenerate = service.generateCallCount
        viewModel.generateNewData()
        XCTAssertEqual(service.generateCallCount, callsBeforeManualGenerate)

        clock.advance(by: 59)
        viewModel.tick()
        XCTAssertTrue(viewModel.isHardStopLossBreakActive)
        XCTAssertEqual(viewModel.sessionLimitReason, .stopLoss)

        clock.advance(by: 1)
        viewModel.tick()
        XCTAssertFalse(viewModel.isHardStopLossBreakActive)
        XCTAssertNil(viewModel.sessionLimitReason)
        XCTAssertEqual(viewModel.sessionResultUSD, 0)
        XCTAssertFalse(viewModel.isSessionPlayBlocked)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Перерыв завершён" }.count,
            1
        )
    }

    func testSessionStopWinBlocksGenerationUntilReset() {
        let service = MockRandomizerService(numbers: [44, 55, 66])
        let notifications = MockNotificationService()
        let viewModel = RandomizerView(
            service: service,
            notificationService: notifications,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setShotAttempts(10)
        viewModel.setSessionStopWinUSD(100)
        viewModel.addShotJournalEntry(resultUSD: 40, comment: "", applyToBankroll: false)
        viewModel.addShotJournalEntry(resultUSD: 60, comment: "", applyToBankroll: false)

        XCTAssertEqual(viewModel.sessionResultUSD, 100)
        XCTAssertEqual(viewModel.sessionLimitReason, .stopWin)
        XCTAssertTrue(viewModel.isSessionPlayBlocked)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Stop-win достигнут" }.count,
            1
        )

        XCTAssertEqual(service.generateCallCount, 1)
        viewModel.generateNewData()
        XCTAssertEqual(service.generateCallCount, 1)
    }

    func testShotAvailabilityUsesBankrollAndLimit() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setShotLimitNL(25)
        viewModel.setCurrentBankrollUSD(624)

        XCTAssertEqual(viewModel.shotBankrollThresholdBuyIns, 25)
        XCTAssertEqual(viewModel.shotAttempts, 2)
        XCTAssertEqual(viewModel.requiredBankrollForShot, 625)
        XCTAssertEqual(viewModel.shotBudget, 50)
        XCTAssertEqual(viewModel.missingBankrollForShot, 1)
        XCTAssertEqual(viewModel.bankrollReserveForShot, 0)
        XCTAssertEqual(viewModel.bankrollReserveForShotInBuyIns, 0)
        XCTAssertFalse(viewModel.canTakeShot)

        viewModel.setCurrentBankrollUSD(625)

        XCTAssertEqual(viewModel.missingBankrollForShot, 0)
        XCTAssertEqual(viewModel.bankrollReserveForShot, 0)
        XCTAssertEqual(viewModel.bankrollReserveForShotInBuyIns, 0)
        XCTAssertTrue(viewModel.canTakeShot)

        viewModel.setCurrentBankrollUSD(700)

        XCTAssertEqual(viewModel.bankrollReserveForShot, 75)
        XCTAssertEqual(viewModel.bankrollReserveForShotInBuyIns, 3)
        XCTAssertTrue(viewModel.canTakeShot)
    }

    func testBankrollSettingsPersistBetweenViewModelInstances() {
        let suite = "RandomizerTests.BankrollPersistence.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            return XCTFail("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        let settingsURL = makeSettingsFileURL()
        let journalURL = makeShotJournalFileURL()

        do {
            let viewModel = RandomizerView(
                service: MockRandomizerService(),
                autoStartTimer: false,
                defaults: defaults,
                bankrollSettingsFileURL: settingsURL,
                shotJournalFileURL: journalURL
            )
            viewModel.setCurrentBankrollUSD(730)
            viewModel.setShotLimitNL(25)
            viewModel.setShotBankrollThresholdBuyIns(30)
            viewModel.setShotAttempts(3)
            viewModel.setFatigueWarningMinutes(45)
            viewModel.setFatigueCriticalMinutes(70)
            viewModel.setRandomizerRangeBoundaries(lowUpperBound: 25, midUpperBound: 75)
            viewModel.setSessionStopLossUSD(120)
            viewModel.setSessionStopWinUSD(240)
            viewModel.setHardStopLossEnabled(true)
            viewModel.setHardStopLossBreakMinutes(20)
            viewModel.addShotJournalEntry(resultUSD: 40, comment: "", applyToBankroll: false)
        }

        let reloaded = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL
        )
        XCTAssertEqual(reloaded.currentBankrollUSD, 730)
        XCTAssertEqual(reloaded.shotLimitNL, 25)
        XCTAssertEqual(reloaded.shotBankrollThresholdBuyIns, 30)
        XCTAssertEqual(reloaded.shotAttempts, 3)
        XCTAssertEqual(reloaded.fatigueWarningMinutes, 60)
        XCTAssertEqual(reloaded.fatigueCriticalMinutes, 120)
        XCTAssertEqual(reloaded.randomizerLowUpperBound, 25)
        XCTAssertEqual(reloaded.randomizerMidUpperBound, 75)
        XCTAssertEqual(reloaded.sessionStopLossUSD, 120)
        XCTAssertEqual(reloaded.sessionStopWinUSD, 240)
        XCTAssertTrue(reloaded.hardStopLossEnabled)
        XCTAssertEqual(reloaded.hardStopLossBreakMinutes, 20)
        XCTAssertEqual(reloaded.sessionResultUSD, 40)
        XCTAssertNil(reloaded.sessionLimitReason)
        XCTAssertTrue(FileManager.default.fileExists(atPath: settingsURL.path))

        defaults.removePersistentDomain(forName: suite)
    }

    func testRandomizerRangeBoundariesAreClamped() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setRandomizerRangeBoundaries(lowUpperBound: 90, midUpperBound: 80)
        XCTAssertEqual(viewModel.randomizerLowUpperBound, 90)
        XCTAssertEqual(viewModel.randomizerMidUpperBound, 91)

        viewModel.setRandomizerRangeBoundaries(lowUpperBound: 999, midUpperBound: 999)
        XCTAssertEqual(viewModel.randomizerLowUpperBound, 97)
        XCTAssertEqual(viewModel.randomizerMidUpperBound, 98)
    }

    func testFatigueThresholdsAreClampedAndOrdered() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setFatigueWarningMinutes(60)
        XCTAssertEqual(viewModel.fatigueWarningMinutes, 60)
        XCTAssertEqual(viewModel.fatigueCriticalMinutes, 120)

        viewModel.setFatigueCriticalMinutes(30)
        XCTAssertEqual(viewModel.fatigueCriticalMinutes, 120)

        viewModel.setFatigueWarningMinutes(9_999)
        XCTAssertEqual(viewModel.fatigueWarningMinutes, 1380)
        XCTAssertEqual(viewModel.fatigueCriticalMinutes, 1440)

        viewModel.setFatigueCriticalMinutes(9_999)
        XCTAssertEqual(viewModel.fatigueCriticalMinutes, 1440)
    }

    func testExpiredHardStopLossBreakIsClearedOnReload() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let defaults = makeCleanDefaults()
        let settingsURL = makeSettingsFileURL()
        let journalURL = makeShotJournalFileURL()

        do {
            let viewModel = RandomizerView(
                service: MockRandomizerService(),
                autoStartTimer: false,
                defaults: defaults,
                bankrollSettingsFileURL: settingsURL,
                shotJournalFileURL: journalURL,
                currentDateProvider: { clock.now }
            )
            viewModel.setHardStopLossEnabled(true)
            viewModel.setHardStopLossBreakMinutes(1)
            viewModel.setSessionStopLossUSD(10)
            viewModel.addShotJournalEntry(resultUSD: -10, comment: "", applyToBankroll: false)

            XCTAssertEqual(viewModel.sessionLimitReason, .stopLoss)
            XCTAssertTrue(viewModel.isHardStopLossBreakActive)
        }

        clock.advance(by: 61)

        let reloaded = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL,
            currentDateProvider: { clock.now }
        )

        XCTAssertNil(reloaded.sessionLimitReason)
        XCTAssertEqual(reloaded.sessionResultUSD, 0)
        XCTAssertFalse(reloaded.isHardStopLossBreakActive)
        XCTAssertFalse(reloaded.isSessionPlayBlocked)
    }

    func testShotAttemptsCannotGoBelowOne() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setShotAttempts(1)
        viewModel.decrementShotAttempts()
        XCTAssertEqual(viewModel.shotAttempts, 1)

        viewModel.incrementShotAttempts()
        XCTAssertEqual(viewModel.shotAttempts, 2)

        viewModel.setShotAttempts(-5)
        XCTAssertEqual(viewModel.shotAttempts, 1)
    }

    func testShotJournalEntryPersistsAndUpdatesBankroll() {
        let defaults = makeCleanDefaults()
        let settingsURL = makeSettingsFileURL()
        let journalURL = makeShotJournalFileURL()

        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL
        )
        viewModel.setShotLimitNL(25)
        viewModel.setShotAttempts(2)
        viewModel.setCurrentBankrollUSD(700)
        for _ in 0..<3 {
            viewModel.tick()
        }

        viewModel.addShotJournalEntry(resultUSD: -50, comment: "неудачный шот", applyToBankroll: true)

        XCTAssertEqual(viewModel.currentBankrollUSD, 650)
        XCTAssertEqual(viewModel.shotJournalEntries.count, 1)
        XCTAssertEqual(viewModel.shotJournalEntries[0].limitNL, 25)
        XCTAssertEqual(viewModel.shotJournalEntries[0].sessionDurationSeconds, 3)
        XCTAssertEqual(viewModel.shotJournalEntries[0].resultUSD, -50)
        XCTAssertEqual(viewModel.shotJournalEntries[0].resultBuyIns, -2)
        XCTAssertEqual(viewModel.shotJournalEntries[0].bankrollAfterUSD, 650)
        XCTAssertTrue(viewModel.shotJournalEntries[0].applyToBankroll)
        XCTAssertEqual(viewModel.shotJournalEntries[0].comment, "неудачный шот")
        XCTAssertTrue(FileManager.default.fileExists(atPath: journalURL.path))

        let reloaded = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL
        )
        XCTAssertEqual(reloaded.shotJournalEntries.count, 1)
        XCTAssertEqual(reloaded.shotJournalEntries[0].sessionDurationSeconds, 3)
        XCTAssertEqual(reloaded.shotJournalEntries[0].resultUSD, -50)
    }

    func testShotJournalEntryCanBeSavedWithoutApplyingToBankroll() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )
        viewModel.setShotLimitNL(25)
        viewModel.setCurrentBankrollUSD(500)

        viewModel.addShotJournalEntry(resultUSD: 25, comment: "", applyToBankroll: false)

        XCTAssertEqual(viewModel.currentBankrollUSD, 500)
        XCTAssertEqual(viewModel.shotJournalEntries.count, 1)
        XCTAssertFalse(viewModel.shotJournalEntries[0].applyToBankroll)
        XCTAssertEqual(viewModel.shotJournalEntries[0].bankrollAfterUSD, 500)
        XCTAssertEqual(viewModel.shotJournalEntries[0].resultBuyIns, 1)
    }

    func testShotLocksAfterCumulativeMinusTwoBuyIns() {
        let notifications = MockNotificationService()
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            notificationService: notifications,
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )
        viewModel.setShotLimitNL(25)
        viewModel.setCurrentBankrollUSD(700)

        viewModel.addShotJournalEntry(resultUSD: -30, comment: "", applyToBankroll: false)
        XCTAssertFalse(viewModel.isShotLocked)
        XCTAssertEqual(viewModel.currentShotResultUSD, -30)
        XCTAssertTrue(viewModel.isShotAvailable)

        viewModel.addShotJournalEntry(resultUSD: -20, comment: "", applyToBankroll: false)
        XCTAssertTrue(viewModel.isShotLocked)
        XCTAssertEqual(viewModel.currentShotResultUSD, -50)
        XCTAssertFalse(viewModel.isShotAvailable)
        XCTAssertEqual(
            notifications.notifications.filter { $0.title == "Игра запрещена по stop-loss" }.count,
            1
        )
    }

    func testShotAutoUnlocksAfterBankrollRecoveryToTwentyFiveBuyIns() {
        let defaults = makeCleanDefaults()
        let settingsURL = makeSettingsFileURL()
        let journalURL = makeShotJournalFileURL()

        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL
        )
        viewModel.setShotLimitNL(25)
        viewModel.setShotBankrollThresholdBuyIns(25)
        viewModel.setShotAttempts(2)
        viewModel.setCurrentBankrollUSD(625)

        viewModel.addShotJournalEntry(resultUSD: -50, comment: "", applyToBankroll: true)
        XCTAssertTrue(viewModel.isShotLocked)
        XCTAssertEqual(viewModel.currentBankrollUSD, 575)
        XCTAssertEqual(viewModel.currentShotResultUSD, -50)
        XCTAssertFalse(viewModel.isShotAvailable)

        let reloadedLocked = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: defaults,
            bankrollSettingsFileURL: settingsURL,
            shotJournalFileURL: journalURL
        )
        XCTAssertTrue(reloadedLocked.isShotLocked)
        XCTAssertEqual(reloadedLocked.currentShotResultUSD, -50)

        reloadedLocked.setCurrentBankrollUSD(625)
        XCTAssertFalse(reloadedLocked.isShotLocked)
        XCTAssertEqual(reloadedLocked.currentShotResultUSD, 0)
        XCTAssertTrue(reloadedLocked.isShotAvailable)
    }

    func testShotRulesUseConfiguredBuyInSettings() {
        let viewModel = RandomizerView(
            service: MockRandomizerService(),
            autoStartTimer: false,
            defaults: makeCleanDefaults(),
            bankrollSettingsFileURL: makeSettingsFileURL(),
            shotJournalFileURL: makeShotJournalFileURL()
        )

        viewModel.setShotLimitNL(25)
        viewModel.setShotBankrollThresholdBuyIns(30)
        viewModel.setShotAttempts(3)
        viewModel.setCurrentBankrollUSD(749)

        XCTAssertEqual(viewModel.requiredBankrollForShot, 750)
        XCTAssertEqual(viewModel.shotBudget, 75)
        XCTAssertFalse(viewModel.canTakeShot)

        viewModel.setCurrentBankrollUSD(750)
        XCTAssertTrue(viewModel.canTakeShot)

        viewModel.addShotJournalEntry(resultUSD: -70, comment: "", applyToBankroll: false)
        XCTAssertFalse(viewModel.isShotLocked)

        viewModel.addShotJournalEntry(resultUSD: -5, comment: "", applyToBankroll: false)
        XCTAssertTrue(viewModel.isShotLocked)

        viewModel.setCurrentBankrollUSD(750)
        XCTAssertFalse(viewModel.isShotLocked)
        XCTAssertEqual(viewModel.currentShotResultUSD, 0)
    }

    private func makeCleanDefaults() -> UserDefaults {
        let suite = "RandomizerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            fatalError("Unable to create suite defaults")
        }
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func makeSettingsFileURL() -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("RandomizerTests.\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("settings.json", isDirectory: false)
    }

    private func makeShotJournalFileURL() -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("RandomizerTests.\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("shot_journal.json", isDirectory: false)
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

private struct SentNotification {
    let id: String
    let title: String
    let body: String
}

private final class MockNotificationService: NotificationServiceProtocol {
    private(set) var authorizationRequestsCount = 0
    private(set) var notifications: [SentNotification] = []

    func requestAuthorizationIfNeeded(completion: @escaping @Sendable (Bool) -> Void) {
        authorizationRequestsCount += 1
        completion(true)
    }

    func postNotification(id: String, title: String, body: String) {
        notifications.append(SentNotification(id: id, title: title, body: body))
    }
}

private final class TestClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
