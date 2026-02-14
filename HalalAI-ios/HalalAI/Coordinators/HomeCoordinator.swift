//
//  HomeCoordinator.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

enum HomeCoordinator: Hashable {
    case home
    case scanner
    case quran
    case sura(suraIndex: Int)

    @MainActor
    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            screenFactory.makeHomeView()
        case .scanner:
            screenFactory.makeScannerView()
        case .quran:
            screenFactory.makeQuranListView()
        case .sura(let suraIndex):
            screenFactory.makeSuraReaderView(suraIndex: suraIndex)
        }
    }
}
