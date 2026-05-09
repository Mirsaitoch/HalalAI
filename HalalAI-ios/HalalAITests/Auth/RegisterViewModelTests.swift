//
//  RegisterViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct RegisterViewModelTests {

    // MARK: - Email Validation

    @Test("Valid emails pass validation",
          arguments: ["test@test.com", "user@domain.org", "a.b+c@d.co"])
    func validEmails(email: String) {
        let (vm, _, _) = makeSUT()
        #expect(vm.isValidEmail(email) == true)
    }

    @Test("Invalid emails fail validation",
          arguments: ["", "test", "test@", "@test.com", "test@.com", "test test@com"])
    func invalidEmails(email: String) {
        let (vm, _, _) = makeSUT()
        #expect(vm.isValidEmail(email) == false)
    }

    // MARK: - isFormValid

    @Test("Form valid with correct inputs")
    func formValidWithCorrectInputs() {
        let (vm, _, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "12345678"
        vm.confirmPassword = "12345678"
        #expect(vm.isFormValid == true)
    }

    @Test("Form invalid when password too short")
    func formInvalidShortPassword() {
        let (vm, _, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "1234567"  // 7 chars, need 8
        vm.confirmPassword = "1234567"
        #expect(vm.isFormValid == false)
    }

    @Test("Form invalid when passwords don't match")
    func formInvalidPasswordMismatch() {
        let (vm, _, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "12345678"
        vm.confirmPassword = "87654321"
        #expect(vm.isFormValid == false)
    }

    @Test("Form invalid with empty email")
    func formInvalidEmptyEmail() {
        let (vm, _, _) = makeSUT()
        vm.email = ""
        vm.password = "12345678"
        vm.confirmPassword = "12345678"
        #expect(vm.isFormValid == false)
    }

    @Test("Form invalid with invalid email")
    func formInvalidBadEmail() {
        let (vm, _, _) = makeSUT()
        vm.email = "not-an-email"
        vm.password = "12345678"
        vm.confirmPassword = "12345678"
        #expect(vm.isFormValid == false)
    }

    // MARK: - register()

    @Test("Successful registration saves auth")
    func successfulRegister() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "12345678"
        vm.confirmPassword = "12345678"

        await vm.register()

        #expect(authManager.saveAuthCallCount == 1)
        #expect(vm.showError == false)
    }

    @Test("Registration with short password shows error")
    func registerShortPasswordError() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "short"
        vm.confirmPassword = "short"

        await vm.register()

        #expect(vm.showError == true)
        #expect(authManager.saveAuthCallCount == 0)
    }

    @Test("Registration with mismatched passwords shows error")
    func registerMismatchedPasswordsError() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "12345678"
        vm.confirmPassword = "87654321"

        await vm.register()

        #expect(vm.showError == true)
        #expect(authManager.saveAuthCallCount == 0)
    }

    @Test("Registration with invalid email shows error")
    func registerInvalidEmailError() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "bad-email"
        vm.password = "12345678"
        vm.confirmPassword = "12345678"

        await vm.register()

        #expect(vm.showError == true)
        #expect(vm.errorMessage.contains("email") == true)
        #expect(authManager.saveAuthCallCount == 0)
    }

    @Test("Registration service failure shows error")
    func registerServiceFailure() async {
        let (vm, authManager, authService) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "12345678"
        vm.confirmPassword = "12345678"
        authService.registerResult = .failure(AuthError.userAlreadyExists)

        await vm.register()

        #expect(vm.showError == true)
        #expect(authManager.saveAuthCallCount == 0)
    }

    // MARK: - Helpers

    private func makeSUT() -> (RegisterView.ViewModel, MockAuthManager, MockAuthService) {
        let authManager = MockAuthManager()
        let authService = MockAuthService()
        let vm = RegisterView.ViewModel(authManager: authManager, authService: authService)
        return (vm, authManager, authService)
    }
}
