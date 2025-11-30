//
//  SettingsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 12.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var chatService = ChatService.shared
    @State private var isApiKeyVisible = false
    
    var body: some View {
        Form {
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
        }
        .navigationTitle("Настройки")
    }
}

#Preview {
    SettingsView()
}
