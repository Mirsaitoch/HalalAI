//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var chatService = ChatService.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var isApiKeyVisible = false
    
    var body: some View {
        Form {
            // Информация о пользователе
            if let user = authManager.currentUser {
                Section(header: Text("Аккаунт")) {
                    HStack {
                        Text("Пользователь")
                        Spacer()
                        Text(user.username)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("API ключ провайдера")) {
                if isApiKeyVisible {
                    TextField("Введите ключ", text: $chatService.userApiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                } else {
                    SecureField("Введите ключ", text: $chatService.userApiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                }
                
                Toggle("Показать ключ", isOn: $isApiKeyVisible)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                if !chatService.userApiKey.isEmpty {
                    Button(role: .destructive) {
                        chatService.userApiKey = ""
                    } label: {
                        Label("Очистить ключ", systemImage: "trash")
                    }
                }
                
                Text("Если указать API ключ (например, OpenAI или совместимый), ответы будут генерироваться через удалённую модель. Без ключа применяется локальная модель HalalAI.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Выход из аккаунта
            Section {
                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    HStack {
                        Spacer()
                        Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Настройки")
    }
}

#Preview {
    SettingsView()
}
