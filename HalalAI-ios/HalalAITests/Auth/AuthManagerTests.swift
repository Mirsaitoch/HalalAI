//
//  AuthManagerTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct AuthManagerTests {

    // Using unique keys per test via fresh UserDefaults state

    // MARK: - Initial State

    @Test("Fresh AuthManager starts unauthenticated when no stored data")
    func initialStateUnauthenticated() {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()
        #expect(manager.authState == .unauthenticated)
        #expect(manager.currentUser == nil)
        #expect(manager.isAuthenticated == false)
        #expect(manager.isGuest == false)
        cleanupUserDefaults()
    }

    // MARK: - saveAuth

    @Test("saveAuth sets authenticated state and stores user")
    func saveAuthSetsState() {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()
        let response = AuthResponse(
            token: "test-token-123",
            type: "Bearer",
            userId: 42,
            email: "test@test.com"
        )

        manager.saveAuth(response)

        #expect(manager.authState == .authenticated)
        #expect(manager.isAuthenticated == true)
        #expect(manager.currentUser?.email == "test@test.com")
        #expect(manager.currentUser?.userId == 42)
        #expect(manager.authToken == "test-token-123")
        #expect(manager.errorMessage == nil)
        cleanupUserDefaults()
    }

    // MARK: - logout

    @Test("logout clears state and returns to unauthenticated")
    func logoutClearsState() {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()
        let response = AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com")
        manager.saveAuth(response)

        manager.logout()

        #expect(manager.authState == .unauthenticated)
        #expect(manager.currentUser == nil)
        #expect(manager.isAuthenticated == false)
        #expect(manager.authToken == nil)
        cleanupUserDefaults()
    }

    // MARK: - continueAsGuest

    @Test("continueAsGuest sets guest state")
    func continueAsGuestSetsState() {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()

        manager.continueAsGuest()

        #expect(manager.authState == .guest)
        #expect(manager.isGuest == true)
        #expect(manager.isAuthenticated == false)
        cleanupUserDefaults()
    }

    // MARK: - Persistence

    @Test("Saved auth persists across instances")
    func authPersistsAcrossInstances() {
        cleanupUserDefaults()
        let manager1 = AuthManagerImpl()
        let response = AuthResponse(token: "persist-token", type: "Bearer", userId: 99, email: "persist@test.com")
        manager1.saveAuth(response)

        let manager2 = AuthManagerImpl()
        #expect(manager2.authState == .authenticated)
        #expect(manager2.currentUser?.email == "persist@test.com")
        #expect(manager2.authToken == "persist-token")
        cleanupUserDefaults()
    }

    @Test("Guest state persists across instances")
    func guestPersistsAcrossInstances() {
        cleanupUserDefaults()
        let manager1 = AuthManagerImpl()
        manager1.continueAsGuest()

        let manager2 = AuthManagerImpl()
        #expect(manager2.authState == .guest)
        #expect(manager2.isGuest == true)
        cleanupUserDefaults()
    }

    @Test("Logout clears persistence")
    func logoutClearsPersistence() {
        cleanupUserDefaults()
        let manager1 = AuthManagerImpl()
        manager1.saveAuth(AuthResponse(token: "tok", type: "Bearer", userId: 1, email: "a@b.com"))
        manager1.logout()

        let manager2 = AuthManagerImpl()
        #expect(manager2.authState == .unauthenticated)
        #expect(manager2.currentUser == nil)
        cleanupUserDefaults()
    }

    // MARK: - refreshToken

    @Test("refreshToken throws when no token stored")
    func refreshTokenThrowsWithoutToken() async {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()

        do {
            try await manager.refreshToken()
            Issue.record("Expected refreshToken to throw when no token is stored")
        } catch {
            // Expected
        }
        cleanupUserDefaults()
    }

    // MARK: - Computed Properties

    @Test("isAuthenticated requires both authenticated state and user")
    func isAuthenticatedRequiresBoth() {
        cleanupUserDefaults()
        let manager = AuthManagerImpl()
        #expect(manager.isAuthenticated == false)

        manager.authState = .authenticated
        // still no currentUser
        #expect(manager.isAuthenticated == false)

        manager.currentUser = AuthResponse(token: "t", type: "Bearer", userId: 1, email: "a@b.com")
        #expect(manager.isAuthenticated == true)
        cleanupUserDefaults()
    }

    // MARK: - Helpers

    private func cleanupUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "HalalAI.authToken")
        UserDefaults.standard.removeObject(forKey: "HalalAI.currentUser")
        UserDefaults.standard.removeObject(forKey: "HalalAI.isGuest")
    }
}
