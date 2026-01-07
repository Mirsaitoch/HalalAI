//
//  IngredientModels.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 29.12.2025.
//

import Foundation

enum IngredientStatus: String, Codable {
    case halal = "halal"
    case haram = "haram"
    case mushbooh = "mushbooh"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .halal:
            return "Халяль"
        case .haram:
            return "Харам"
        case .mushbooh:
            return "Сомнительно"
        case .unknown:
            return "Неизвестно"
        }
    }
    
    var color: String {
        switch self {
        case .halal:
            return "greenForeground"
        case .haram:
            return "red"
        case .mushbooh:
            return "orange"
        case .unknown:
            return "gray"
        }
    }
}

struct Ingredient: Codable, Identifiable {
    let id: UUID
    let eCode: String?
    let status: IngredientStatus
    let nameRu: String
    let nameEn: String
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case eCode = "e_code"
        case status
        case nameRu = "name_ru"
        case nameEn = "name_en"
        case note
    }
    
    init(id: UUID = UUID(), eCode: String?, status: IngredientStatus, nameRu: String, nameEn: String, note: String? = nil) {
        self.id = id
        self.eCode = eCode
        self.status = status
        self.nameRu = nameRu
        self.nameEn = nameEn
        self.note = note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.eCode = try container.decodeIfPresent(String.self, forKey: .eCode)?.isEmpty == false 
            ? try container.decodeIfPresent(String.self, forKey: .eCode) 
            : nil
        let statusString = try container.decode(String.self, forKey: .status)
        self.status = IngredientStatus(rawValue: statusString) ?? .unknown
        self.nameRu = try container.decode(String.self, forKey: .nameRu)
        self.nameEn = try container.decode(String.self, forKey: .nameEn)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)?.isEmpty == false
            ? try container.decodeIfPresent(String.self, forKey: .note)
            : nil
    }
}

struct ProductAnalysis {
    let ingredients: [DetectedIngredient]
    let overallStatus: IngredientStatus
    let haramIngredients: [DetectedIngredient]
    let mushboohIngredients: [DetectedIngredient]
    
    var isHalal: Bool {
        return overallStatus == .halal && haramIngredients.isEmpty && mushboohIngredients.isEmpty
    }
}

struct DetectedIngredient: Identifiable {
    let id: UUID
    let name: String
    let matchedIngredient: Ingredient?
    let status: IngredientStatus
    
    init(name: String, matchedIngredient: Ingredient? = nil) {
        self.id = UUID()
        self.name = name
        self.matchedIngredient = matchedIngredient
        self.status = matchedIngredient?.status ?? .unknown
    }
}

