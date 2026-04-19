//
//  VerseView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 09.01.2026.
//

import SwiftUI

struct VerseView: View {
    @State var verseService: VerseService

    var body: some View {
        VStack {
            if let verse = verseService.verseOfTheDay {
                VStack(alignment: .leading, spacing: 12) {
                    // Информация о суре
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Аят дня")
                            .font(.headline)
                        HStack {
                            Text(verse.suraTitle)
                            Text("Сура \(verse.suraIndex):\(verse.verseNumber)")
                        }
                        .font(.caption)
                    }
                    .foregroundStyle(.darkGreen)

                    Divider()
                        .padding(.vertical, 4)
                    
                    // Текст аята
                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(.greenForeground)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
        .task {
            do {
                try await verseService.fetchVerseOfTheDay()
            } catch {
                print("Ошибка при получении аята-дня: \(error)")
            }
        }
    }
}
