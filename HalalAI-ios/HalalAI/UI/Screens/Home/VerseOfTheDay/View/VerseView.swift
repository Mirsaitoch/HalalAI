//
//  VerseView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 09.01.2026.
//

import SwiftUI

struct VerseView: View {
    var verseService: VerseService
    var body: some View {
        Text(verseService.verseOfTheDay?.text ?? "اَلسَّلَامُ عَلَيْكُمْ")
            .task {
                do {
                    try await verseService.fetchVerseOfTheDay()
                } catch {
                    print("Ошибка при получении аята-дня: \(error)")
                }
            }
    }
}
