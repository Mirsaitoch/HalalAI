//
//  ChatService.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 25.10.2025.
//

import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var chatState: ChatState = .idle
    @Published var connectionState: ConnectionState = .connected
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Добавляем сообщение пользователя
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        
        // Устанавливаем состояние "печатает"
        chatState = .typing
        
        // Имитируем отправку запроса к API
        Task {
            await simulateAIResponse(for: text)
        }
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }
        
        // Удаляем последнее сообщение AI (если есть)
        if let lastAIMessage = messages.last, lastAIMessage.role == .assistant {
            messages.removeLast()
        }
        
        chatState = .typing
        
        Task {
            await simulateAIResponse(for: lastUserMessage.text)
        }
    }
    
    func clearChat() {
        messages.removeAll()
        chatState = .idle
    }
    
    // MARK: - Private Methods
    
    private func simulateAIResponse(for userText: String) async {
        // Имитируем задержку сети
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 секунды
        
        // Генерируем ответ в зависимости от введенного текста
        let response = generateAIResponse(for: userText)
        
        let aiMessage = ChatMessage(role: .assistant, text: response)
        messages.append(aiMessage)
        
        chatState = .idle
    }
    
    private func generateAIResponse(for userText: String) -> String {
        let lowercasedText = userText.lowercased()
        
        if lowercasedText.contains("привет") || lowercasedText.contains("салам") {
            return "Ассаламу алейкум! 👋\n\nЯ — HalalAI, ваш халяль-помощник. Готов ответить на ваши вопросы о халяль продуктах, брендах и исламских принципах питания.\n\nЧем могу помочь?"
        } else if lowercasedText.contains("халяль") {
            return "Халяль — это разрешенное в исламе. В контексте питания это означает продукты, которые соответствуют исламским принципам:\n\n• Мясо должно быть зарезано по исламским правилам\n• Не должно содержать алкоголь или свинину\n• Процесс производства должен соответствовать исламским нормам\n\nЕсть ли конкретные продукты, о которых хотите узнать?"
        } else if lowercasedText.contains("мясо") {
            return "Халяль мясо должно соответствовать следующим требованиям:\n\n• Животное должно быть зарезано мусульманином\n• При забое произносится «Бисмиллах»\n• Кровь должна быть полностью слита\n• Животное должно быть здоровым\n\nКакое именно мясо вас интересует?"
        } else if lowercasedText.contains("молочн") {
            return "Молочные продукты обычно халяль, если:\n\n• Не содержат алкогольных добавок\n• Не содержат свиных компонентов (желатин)\n• Произведены с соблюдением санитарных норм\n\nПроверяйте состав на наличие желатина животного происхождения."
        } else if lowercasedText.contains("бренд") {
            return "Популярные халяль бренды:\n\n• **Мясо**: «Халяль», «Ас-Салам»\n• **Молочные**: «Акбарс», «Простоквашино»\n• **Кондитерские**: «Бахетле», «Рахат»\n\nВсегда проверяйте сертификаты халяль на упаковке!"
        } else {
            return "Спасибо за ваш вопрос! 🤲\n\nЯ специализируюсь на вопросах халяль питания. Могу помочь с:\n\n• Определением халяль продуктов\n• Информацией о брендах\n• Исламскими принципами питания\n• Сертификацией продуктов\n\nЗадайте более конкретный вопрос, и я с радостью помогу!"
        }
    }
}
