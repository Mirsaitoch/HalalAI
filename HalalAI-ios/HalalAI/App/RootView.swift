//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = DependencyContainer.shared.authManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
               RouterView()
           } else {
               AuthFlowView()
           }
       }
   }
}
