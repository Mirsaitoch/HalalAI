//
//  LoginViewModelTests.swift
//  HalalAITests
//

import Foundation
import Testing
@testable import HalalAI

@MainActor
struct LoginViewModelTests {

    // MARK: - isDisable

    @Test("Login disabled when email empty")
    func disabledWithEmptyEmail() {
        let (vm, _, _) = makeSUT()
        vm.email = ""
        vm.password = "password"
        #expect(vm.isDisable == true)
    }

    @Test("Login disabled when password empty")
    func disabledWithEmptyPassword() {
        let (vm, _, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = ""
        #expect(vm.isDisable == true)
    }

    @Test("Login enabled when both fields filled")
    func enabledWithBothFields() {
        let (vm, _, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "password"
        #expect(vm.isDisable == false)
    }

    @Test("Login disabled when service is loading")
    func disabledWhileLoading() {
        let (vm, _, authService) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "password"
        authService.isLoading = true
        #expect(vm.isDisable == true)
    }

    // MARK: - login()

    @Test("Successful login saves auth")
    func successfulLogin() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "password123"

        await vm.login()

        #expect(authManager.saveAuthCallCount == 1)
        #expect(authManager.authState == .authenticated)
        #expect(vm.showError == false)
    }

    @Test("Login with empty fields shows error")
    func loginEmptyFieldsShowsError() async {
        let (vm, authManager, _) = makeSUT()
        vm.email = "   "
        vm.password = ""

        await vm.login()

        #expect(vm.showError == true)
        #expect(vm.errorMessage == "Заполните все поля")
        #expect(authManager.saveAuthCallCount == 0)
    }

    @Test("Login failure shows error message")
    func loginFailureShowsError() async {
        let (vm, authManager, authService) = makeSUT()
        vm.email = "test@test.com"
        vm.password = "wrong"
        authService.loginResult = .failure(AuthError.invalidCredentials)

        await vm.login()

        #expect(vm.showError == true)
        #expect(vm.errorMessage.contains("Неверный") == true)
        #expect(authManager.saveAuthCallCount == 0)
    }

    // MARK: - Helpers

    private func makeSUT() -> (LoginView.ViewModel, MockAuthManager, MockAuthService) {
        let authManager = MockAuthManager()
        let authService = MockAuthService()
        let vm = LoginView.ViewModel(authManager: authManager, authService: authService)
        return (vm, authManager, authService)
    }
}
