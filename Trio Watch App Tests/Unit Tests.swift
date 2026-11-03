import SwiftUI
import Testing
@testable import Trio_Watch_App
import WatchConnectivity

@MainActor @Suite("Watch App Tests") final class TrioWatchAppTests {
    var watchState = WatchState()

    /// Waits for UI updates that WatchState schedules on the main queue
    private func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline { return false }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return true
    }

    /// Delivers an acknowledgment the way the iPhone app sends it
    private func receiveAcknowledgment(_ code: AcknowledgmentCode, success: Bool = true, message: String) {
        watchState.session(WCSession.default, didReceiveMessage: [
            WatchMessageKeys.acknowledged: success,
            WatchMessageKeys.message: message,
            WatchMessageKeys.ackCode: code.rawValue
        ])
    }

    // MARK: - Color Conversion Tests

    @Test("Hex string to color conversion") func testHexStringToColor() throws {
        // Compare resolved RGB values; named colors like Color.white are not equal to RGB colors
        let environment = EnvironmentValues()
        func resolved(_ color: Color) -> Color.Resolved { color.resolve(in: environment) }
        func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color.Resolved {
            resolved(Color(red: red / 255, green: green / 255, blue: blue / 255))
        }

        #expect(resolved("#FFFFFF".toColor()) == rgb(255, 255, 255))
        #expect(resolved("#000000".toColor()) == rgb(0, 0, 0))
        #expect(resolved("#FF0000".toColor()) == rgb(255, 0, 0))
        #expect(resolved("#34C759".toColor()) == rgb(52, 199, 89))
        #expect(resolved("FF0000".toColor()) == rgb(255, 0, 0))
        #expect(resolved("invalid".toColor()) == rgb(0, 0, 0))
    }

    // MARK: - WatchState Tests

    @Test("WatchState initialization with default values") func testWatchStateInitialization() throws {
        #expect(watchState.currentGlucose == "--")
        #expect(watchState.currentGlucoseColorString == "#ffffff")
        #expect(watchState.glucoseValues.isEmpty)
        #expect(watchState.iob == "--")
        #expect(watchState.cob == "--")
        #expect(watchState.lastLoopTime == "--")
    }

    @Test("Bolus limits have correct default values") func testBolusLimits() throws {
        #expect(watchState.maxBolus == Decimal(10))
        #expect(watchState.bolusIncrement == Decimal(0.05))
    }

    @Test("Meal limits have correct default values") func testMealLimits() throws {
        #expect(watchState.maxCarbs == Decimal(250))
        #expect(watchState.maxFat == Decimal(250))
        #expect(watchState.maxProtein == Decimal(250))
    }

    @Test("Meal bolus combo state follows the iPhone's acknowledgments") func testMealBolusComboState() async throws {
        // Given - Initial state
        #expect(!watchState.isMealBolusCombo)
        #expect(watchState.mealBolusStep == .savingCarbs)

        // When/Then - Carbs are being saved
        receiveAcknowledgment(.savingCarbs, message: "Saving Carbs...")
        #expect(await waitUntil { self.watchState.isMealBolusCombo })
        #expect(watchState.mealBolusStep == .savingCarbs)

        // When/Then - Bolus is being enacted
        receiveAcknowledgment(.enactingBolus, message: "Enacting bolus...")
        #expect(await waitUntil { self.watchState.mealBolusStep == .enactingBolus })
        #expect(watchState.isMealBolusCombo)

        // When/Then - Combo completed
        receiveAcknowledgment(.comboComplete, message: "Carbs and Bolus logged successfully.")
        #expect(await waitUntil { !self.watchState.isMealBolusCombo })
        #expect(watchState.acknowledgementStatus == .success)
        #expect(watchState.acknowledgmentMessage == "Carbs and Bolus logged successfully.")
    }

    @Test("Acknowledgment states transition correctly") func testAcknowledgmentStates() async throws {
        // Given - Initial state
        #expect(watchState.acknowledgementStatus == .pending)
        #expect(!watchState.showAcknowledgmentBanner)

        // When/Then - Success acknowledgment
        watchState.handleAcknowledgment(success: true, message: "Success")
        #expect(watchState.acknowledgementStatus == .success)
        #expect(watchState.acknowledgmentMessage == "Success")
        #expect(await waitUntil { self.watchState.showAcknowledgmentBanner })

        // When/Then - Failure acknowledgment
        watchState.handleAcknowledgment(success: false, message: "Error")
        #expect(watchState.acknowledgementStatus == .failure)
        #expect(watchState.acknowledgmentMessage == "Error")
        #expect(watchState.showAcknowledgmentBanner)
    }
}
