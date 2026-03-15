import Testing
@testable import AtollRPC

@Test func testVersion() async throws {
    #expect(AtollRPCVersion == "1.0.0")
}

@Test func testColorDescriptor() async throws {
    let color = AtollColorDescriptor(red: 0.5, green: 0.3, blue: 0.8)
    #expect(color.red == 0.5)
    #expect(color.green == 0.3)
    #expect(color.blue == 0.8)
    #expect(color.alpha == 1.0)
    #expect(!color.isAccent)
    #expect(AtollColorDescriptor.accent.isAccent)
}

@Test func testLiveActivityDescriptorValidation() async throws {
    let validDescriptor = AtollLiveActivityDescriptor(
        id: "test-activity",
        bundleIdentifier: "com.test.app",
        title: "Test",
        leadingIcon: .symbol(name: "timer")
    )
    #expect(validDescriptor.isValid)
    
    let invalidDescriptor = AtollLiveActivityDescriptor(
        id: "",
        bundleIdentifier: "com.test.app",
        title: "Test",
        leadingIcon: .symbol(name: "timer")
    )
    #expect(!invalidDescriptor.isValid)
}

@Test func testLockScreenWidgetValidation() async throws {
    let widget = AtollLockScreenWidgetDescriptor(
        id: "test-widget",
        bundleIdentifier: "com.test.app",
        content: [
            .text("Hello", font: .system(size: 14))
        ]
    )
    #expect(widget.isValid)
}

@Test func testNotchExperienceValidation() async throws {
    let experience = AtollNotchExperienceDescriptor(
        id: "test-experience",
        bundleIdentifier: "com.test.app",
        tab: .init(
            title: "Test Tab",
            sections: [
                AtollNotchContentSection(
                    elements: [.text("Hello", font: .system(size: 14))]
                )
            ]
        )
    )
    #expect(experience.isValid)
}

@Test func testPriorityOrdering() async throws {
    #expect(AtollLiveActivityPriority.low < AtollLiveActivityPriority.normal)
    #expect(AtollLiveActivityPriority.normal < AtollLiveActivityPriority.high)
    #expect(AtollLiveActivityPriority.high < AtollLiveActivityPriority.critical)
}
