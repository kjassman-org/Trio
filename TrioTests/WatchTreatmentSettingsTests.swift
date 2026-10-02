import Foundation
import Testing
@testable import Trio

@Suite("Watch Treatment Settings") struct WatchTreatmentSettingsTests {
    private func decode(_ json: String) throws -> TrioSettings {
        try JSONDecoder().decode(TrioSettings.self, from: Data(json.utf8))
    }

    @Test("Missing keys keep watch bolus and carbs allowed") func missingKeysDefaultToAllowed() throws {
        let settings = try decode("{}")
        #expect(settings.allowWatchBolus)
        #expect(settings.allowWatchCarbs)
    }

    @Test("Stored false values are decoded") func storedFalseIsDecoded() throws {
        let settings = try decode(#"{"allowWatchBolus": false, "allowWatchCarbs": false}"#)
        #expect(!settings.allowWatchBolus)
        #expect(!settings.allowWatchCarbs)
    }

    @Test("Bolus and carbs are independent") func settingsAreIndependent() throws {
        let settings = try decode(#"{"allowWatchBolus": false}"#)
        #expect(!settings.allowWatchBolus)
        #expect(settings.allowWatchCarbs)
    }

    @Test("Values round-trip through encoding") func roundTrip() throws {
        var settings = TrioSettings()
        settings.allowWatchBolus = false
        settings.allowWatchCarbs = true
        let decoded = try JSONDecoder().decode(TrioSettings.self, from: JSONEncoder().encode(settings))
        #expect(!decoded.allowWatchBolus)
        #expect(decoded.allowWatchCarbs)
    }

    @Test("Bundled defaults allow watch treatments") func bundledDefaultsAllow() throws {
        let defaults = OpenAPS.defaults(for: OpenAPS.Trio.settings)
        let settings = try #require(TrioSettings(from: defaults))
        #expect(settings.allowWatchBolus)
        #expect(settings.allowWatchCarbs)
    }
}
