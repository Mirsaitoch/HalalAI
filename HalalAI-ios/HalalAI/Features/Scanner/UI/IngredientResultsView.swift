//
//  IngredientResultsView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import SwiftUI

struct IngredientResultsView: View {
    let analysis: ProductAnalysis?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.greenBackground.ignoresSafeArea()
                
                if let analysis = analysis {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Общий статус
                            overallStatusCard(analysis)
                            
                            // Харам ингредиенты
                            if !analysis.haramIngredients.isEmpty {
                                haramIngredientsCard(analysis.haramIngredients)
                            }
                            
                            // Сомнительные ингредиенты
                            if !analysis.mushboohIngredients.isEmpty {
                                mushboohIngredientsCard(analysis.mushboohIngredients)
                            }
                            
                            // Все ингредиенты
                            allIngredientsCard(analysis.ingredients)
                        }
                        .padding()
                    }
                } else {
                    Text("Ошибка анализа")
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Результаты анализа")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundStyle(.darkGreen)
                }
            }
        }
    }
    
    private func overallStatusCard(_ analysis: ProductAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: analysis.isHalal ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(analysis.overallStatus.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Статус продукта")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Text(analysis.overallStatus.displayName)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(analysis.overallStatus.color)
                }
                
                Spacer()
            }
            
            if !analysis.isHalal {
                Text(analysis.overallStatus == .haram 
                     ? "Продукт содержит запрещенные ингредиенты"
                     : "Продукт содержит сомнительные ингредиенты")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 4)
    }
    
    private func haramIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Запрещенные ингредиенты")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            
            ForEach(ingredients) { ingredient in
                IngredientRowView(ingredient: ingredient)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 4)
    }
    
    private func mushboohIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("Сомнительные ингредиенты")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            
            ForEach(ingredients) { ingredient in
                IngredientRowView(ingredient: ingredient)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 4)
    }
    
    private func allIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Все ингредиенты")
                .font(.headline)
                .foregroundStyle(.darkGreen)
            
            if ingredients.isEmpty {
                Text("В тексте не найдено совпадений с базой ингредиентов.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            } else {
                ForEach(ingredients) { ingredient in
                    IngredientRowView(ingredient: ingredient, showStatus: true)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 4)
    }
    
}

// MARK: - Ingredient Row View

struct IngredientRowView: View {
    let ingredient: DetectedIngredient
    var showStatus: Bool = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(ingredient.status.color)
                    .frame(width: 8, height: 8)
                
                Text(ingredient.name)
                    .font(.body)
                
                Spacer()
                
                if showStatus {
                    Text(ingredient.status.displayName)
                        .font(.caption)
                        .foregroundStyle(ingredient.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ingredient.status.color.opacity(0.2))
                        .clipShape(.rect(cornerRadius: 8))
                } else if let matched = ingredient.matchedIngredient {
                    Text(matched.nameRu)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                // Кнопка раскрытия, если есть note
                if ingredient.matchedIngredient?.note != nil {
                    Button(isExpanded ? "Свернуть" : "Развернуть", systemImage: isExpanded ? "chevron.up" : "chevron.down") {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .labelStyle(.iconOnly)
                }
            }
            
            // Раскрывающееся поле с note
            if isExpanded, let note = ingredient.matchedIngredient?.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.leading, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

