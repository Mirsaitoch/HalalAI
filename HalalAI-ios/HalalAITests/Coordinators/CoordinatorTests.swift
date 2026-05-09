//
//  CoordinatorTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct CoordinatorTests {

    // MARK: - Initial State

    @Test("Initial state has empty path and home tab")
    func initialState() {
        let sut = Coordinator()

        #expect(sut.path.isEmpty)
        #expect(sut.currentSelectedTab == .home)
    }

    // MARK: - nextStep

    @Test("nextStep appends step to path")
    func nextStepAppends() {
        let sut = Coordinator()

        sut.nextStep(step: .home(.scanner))

        #expect(sut.path.count == 1)
    }

    @Test("nextStep appends multiple steps")
    func nextStepMultiple() {
        let sut = Coordinator()

        sut.nextStep(step: .home(.scanner))
        sut.nextStep(step: .home(.quran))

        #expect(sut.path.count == 2)
    }

    // MARK: - dismiss

    @Test("dismiss removes last step from path")
    func dismissRemovesLast() {
        let sut = Coordinator()
        sut.nextStep(step: .home(.scanner))
        sut.nextStep(step: .home(.quran))

        sut.dismiss()

        #expect(sut.path.count == 1)
    }

    @Test("dismiss on empty path does nothing")
    func dismissEmptyPath() {
        let sut = Coordinator()

        sut.dismiss()

        #expect(sut.path.isEmpty)
    }

    // MARK: - toRoot

    @Test("toRoot clears entire path")
    func toRootClearsPath() {
        let sut = Coordinator()
        sut.nextStep(step: .home(.scanner))
        sut.nextStep(step: .home(.quran))
        sut.nextStep(step: .home(.halalMap))

        sut.toRoot()

        #expect(sut.path.isEmpty)
    }

    // MARK: - selectTab

    @Test("selectTab changes tab and clears path")
    func selectTabChanges() {
        let sut = Coordinator()
        sut.nextStep(step: .home(.scanner))

        sut.selectTab(item: .chat)

        #expect(sut.currentSelectedTab == .chat)
        #expect(sut.path.isEmpty)
    }

    @Test("selectTab same tab resets path to root")
    func selectSameTabResetsPath() {
        let sut = Coordinator()
        sut.nextStep(step: .home(.scanner))
        sut.nextStep(step: .home(.quran))

        sut.selectTab(item: .home)

        #expect(sut.currentSelectedTab == .home)
        #expect(sut.path.isEmpty)
    }

    @Test("selectTab to settings changes tab")
    func selectSettings() {
        let sut = Coordinator()

        sut.selectTab(item: .settings)

        #expect(sut.currentSelectedTab == .settings)
    }
}
