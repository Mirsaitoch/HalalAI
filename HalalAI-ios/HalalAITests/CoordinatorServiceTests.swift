//
//  CoordinatorServiceTests.swift
//  HalalAITests
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import Testing
import SwiftUI
@testable import HalalAI

@Suite("CoordinatorService Tests")
struct CoordinatorServiceTests {
        
    private func createIsolatedService() -> CoordinatorService {
        return CoordinatorService.createForTesting()
    }
    
    private func waitForAsyncOperations() async {
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 секунды
    }
        
    @Test("Singleton instance test")
    func testSingletonInstance() async {
        // Given & When
        let instance1 = CoordinatorService.shared
        let instance2 = CoordinatorService.shared
        
        // Then
        #expect(instance1 === instance2, "CoordinatorService должен быть singleton")
    }
    
    @Test("Factory creates isolated instances test")
    func testFactoryCreatesIsolatedInstances() async {
        // Given & When
        let instance1 = CoordinatorService.createForTesting()
        let instance2 = CoordinatorService.createForTesting()
        
        // Then
        #expect(instance1 !== instance2, "Factory должен создавать разные экземпляры")
    }
        
    @Test("Initial state test")
    func testInitialState() async {
        // Given
        let coordinatorService = createIsolatedService()
        
        // Then
        #expect(coordinatorService.path.isEmpty, "Начальный путь должен быть пустым")
        #expect(coordinatorService.chatTabPath.isEmpty, "Начальный путь чата должен быть пустым")
        #expect(coordinatorService.settingsTabPath.isEmpty, "Начальный путь настроек должен быть пустым")
        #expect(coordinatorService.currentSelectedTab == .chat, "Начальная выбранная вкладка должна быть .chat")
        #expect(coordinatorService.currentStep == nil, "Начальный шаг должен быть nil")
    }
        
    @Test("Next step navigation test")
    func testNextStep() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        
        // When
        coordinatorService.nextStep(step: chatStep)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.count == 1, "Путь должен содержать один шаг")
        #expect(coordinatorService.path.first == chatStep, "Первый шаг должен быть chatStep")
        #expect(coordinatorService.currentStep == chatStep, "currentStep должен быть установлен")
    }
    
    @Test("Multiple next steps test")
    func testMultipleNextSteps() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // When
        coordinatorService.nextStep(step: chatStep)
        coordinatorService.nextStep(step: settingsStep)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.count == 2, "Путь должен содержать два шага")
        #expect(coordinatorService.path[0] == chatStep, "Первый шаг должен быть chatStep")
        #expect(coordinatorService.path[1] == settingsStep, "Второй шаг должен быть settingsStep")
        #expect(coordinatorService.currentStep == settingsStep, "currentStep должен быть последним шагом")
    }
    
    @Test("To root navigation test")
    func testToRoot() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // Добавляем шаги
        coordinatorService.nextStep(step: chatStep)
        coordinatorService.nextStep(step: settingsStep)
        await waitForAsyncOperations()
        
        // When
        coordinatorService.toRoot()
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.isEmpty, "Путь должен быть очищен")
        #expect(coordinatorService.currentStep == nil, "currentStep должен быть nil")
    }
        
    @Test("Select chat tab test")
    func testSelectChatTab() async {
        // Given
        let coordinatorService = createIsolatedService()
        
        // When
        coordinatorService.selectTab(item: .chat)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.currentSelectedTab == .chat, "Выбранная вкладка должна быть .chat")
    }
    
    @Test("Select settings tab test")
    func testSelectSettingsTab() async {
        // Given
        let coordinatorService = createIsolatedService()
        
        // When
        coordinatorService.selectTab(item: .settings)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.currentSelectedTab == .settings, "Выбранная вкладка должна быть .settings")
    }
    
    @Test("Select same tab twice test")
    func testSelectSameTabTwice() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        
        // Добавляем шаг
        coordinatorService.nextStep(step: chatStep)
        await waitForAsyncOperations()
        
        coordinatorService.selectTab(item: .chat)
        await waitForAsyncOperations()
        
        // When - выбираем ту же вкладку снова
        coordinatorService.selectTab(item: .chat)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.isEmpty, "Путь должен быть очищен при повторном выборе той же вкладки")
        #expect(coordinatorService.chatTabPath.isEmpty, "Путь чата должен быть очищен")
    }
    
    @Test("Tab path saving test")
    func testTabPathSaving() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        
        // Добавляем шаг
        coordinatorService.nextStep(step: chatStep)
        await waitForAsyncOperations()
        
        // When - переключаемся на другую вкладку
        coordinatorService.selectTab(item: .settings)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.chatTabPath.count == 1, "Путь чата должен быть сохранен")
        #expect(coordinatorService.chatTabPath.first == chatStep, "Сохраненный путь чата должен содержать chatStep")
    }
    
    @Test("Tab path restoration test")
    func testTabPathRestoration() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // Добавляем шаг и переключаемся
        coordinatorService.nextStep(step: chatStep)
        await waitForAsyncOperations()
        
        coordinatorService.selectTab(item: .settings)
        await waitForAsyncOperations()
        
        coordinatorService.nextStep(step: settingsStep)
        await waitForAsyncOperations()
        
        // When - возвращаемся к чату
        coordinatorService.selectTab(item: .chat)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.count == 1, "Путь должен быть восстановлен")
        #expect(coordinatorService.path.first == chatStep, "Восстановленный путь должен содержать chatStep")
    }
        
    @Test("Step equality test")
    func testStepEquality() async {
        // Given
        let chatStep1 = CoordinatorService.Step.Chat(.chat)
        let chatStep2 = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // Then
        #expect(chatStep1 == chatStep2, "Одинаковые шаги чата должны быть равны")
        #expect(chatStep1 != settingsStep, "Разные типы шагов не должны быть равны")
    }
    
    @Test("Step hashable test")
    func testStepHashable() async {
        // Given
        let chatStep = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // When
        let set: Set<CoordinatorService.Step> = [chatStep, settingsStep]
        
        // Then
        #expect(set.count == 2, "Set должен содержать 2 уникальных элемента")
        #expect(set.contains(chatStep), "Set должен содержать chatStep")
        #expect(set.contains(settingsStep), "Set должен содержать settingsStep")
    }
        
    @Test("Empty path operations test")
    func testEmptyPathOperations() async {
        // Given
        let coordinatorService = createIsolatedService()
        
        // When
        coordinatorService.toRoot()
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.isEmpty, "Путь должен остаться пустым")
        #expect(coordinatorService.currentStep == nil, "currentStep должен быть nil")
    }
    
    @Test("Multiple tab switches test")
    func testMultipleTabSwitches() async {
        // Given
        let coordinatorService = createIsolatedService()
        let chatStep = CoordinatorService.Step.Chat(.chat)
        let settingsStep = CoordinatorService.Step.Settings(.settings)
        
        // When - сложная последовательность операций
        coordinatorService.nextStep(step: chatStep)
        await waitForAsyncOperations()
        
        coordinatorService.selectTab(item: .settings)
        await waitForAsyncOperations()
        
        coordinatorService.nextStep(step: settingsStep)
        await waitForAsyncOperations()
        
        coordinatorService.selectTab(item: .chat)
        await waitForAsyncOperations()
        
        coordinatorService.selectTab(item: .settings)
        await waitForAsyncOperations()
        
        // Then
        #expect(coordinatorService.path.count == 1, "Путь настроек должен быть восстановлен")
        #expect(coordinatorService.path.first == settingsStep, "Восстановленный путь должен содержать settingsStep")
        #expect(coordinatorService.chatTabPath.count == 1, "Путь чата должен быть сохранен")
        #expect(coordinatorService.chatTabPath.first == chatStep, "Сохраненный путь чата должен содержать chatStep")
    }
}
