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
        NavigationView {
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
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Результаты анализа")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.greenForeground)
                }
            }
        }
    }
    
    private func overallStatusCard(_ analysis: ProductAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: analysis.isHalal ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(colorForStatus(analysis.overallStatus))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Статус продукта")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(analysis.overallStatus.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorForStatus(analysis.overallStatus))
                }
                
                Spacer()
            }
            
            if !analysis.isHalal {
                Text(analysis.overallStatus == .haram 
                     ? "Продукт содержит запрещенные ингредиенты"
                     : "Продукт содержит сомнительные ингредиенты")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private func haramIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Запрещенные ингредиенты")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            ForEach(ingredients) { ingredient in
                IngredientRowView(ingredient: ingredient)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private func mushboohIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Сомнительные ингредиенты")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            ForEach(ingredients) { ingredient in
                IngredientRowView(ingredient: ingredient)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private func allIngredientsCard(_ ingredients: [DetectedIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Все ингредиенты")
                .font(.headline)
                .foregroundColor(.greenForeground)
            
            ForEach(ingredients) { ingredient in
                IngredientRowView(ingredient: ingredient, showStatus: true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private func colorForStatus(_ status: IngredientStatus) -> Color {
        switch status {
        case .halal:
            return Color.greenForeground
        case .haram:
            return .red
        case .mushbooh:
            return .orange
        case .unknown:
            return .gray
        }
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
                    .fill(colorForStatus(ingredient.status))
                    .frame(width: 8, height: 8)
                
                Text(ingredient.name)
                    .font(.body)
                
                Spacer()
                
                if showStatus {
                    Text(ingredient.status.displayName)
                        .font(.caption)
                        .foregroundColor(colorForStatus(ingredient.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForStatus(ingredient.status).opacity(0.2))
                        .cornerRadius(8)
                } else if let matched = ingredient.matchedIngredient {
                    Text(matched.nameRu)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Кнопка раскрытия, если есть note
                if ingredient.matchedIngredient?.note != nil {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Раскрывающееся поле с note
            if isExpanded, let note = ingredient.matchedIngredient?.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForStatus(_ status: IngredientStatus) -> Color {
        switch status {
        case .halal:
            return Color.greenForeground
        case .haram:
            return .red
        case .mushbooh:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

