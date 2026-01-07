//
//  RouterView.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 05.10.2025.
//

import SwiftUI

struct RootView: View {
    var authManager: any AuthManager
    
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
