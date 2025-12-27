//
//  ImageTextComponent.swift
//  HalalAI
//
//  Created by Мирсаит Сабирзянов on 18.11.2025.
//

import SwiftUI

struct ImageTextComponent: View {
    let componentSize: ImageTextComponentSize
    let image: ImageResource
    let title: String
    let description: String
    
    private var imageSize: (CGFloat, CGFloat) {
        switch componentSize {
        case .small:
            return (UIScreen.main.bounds.width * 0.3, UIScreen.main.bounds.width * 0.3)
        case .medium:
            return (UIScreen.main.bounds.width * 0.4, UIScreen.main.bounds.width * 0.4)
        case .large:
            return (UIScreen.main.bounds.width * 0.88, UIScreen.main.bounds.width * 0.4)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(image)
                .resizable()
                .frame(width: imageSize.0, height: imageSize.1)
                .padding([.top])
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .foregroundStyle(.darkGreen)
            .frame(height: 60)
        }
        .frame(width: imageSize.0)
        .padding(.horizontal, 13)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.greenForeground)
        }
    }
}

enum ImageTextComponentSize {
    case small
    case medium
    case large
}

#Preview {
    
    ScrollView(.vertical) {
        VStack {
            HStack {
                ImageTextComponent(
                    componentSize: .small,
                    image: .quran,
                    title: "Title",
                    description: "DescriptionDescriptionDescriptionDescriptionDescription"
                )
                ImageTextComponent(
                    componentSize: .small,
                    image: .quran,
                    title: "Title",
                    description: "Description"
                )
            }
            HStack {
                ImageTextComponent(
                    componentSize: .medium,
                    image: .quran,
                    title: "Title",
                    description: "DescriptionDescriptionDescriptionDescriptionDescription"
                )
                ImageTextComponent(
                    componentSize: .medium,
                    image: .quran,
                    title: "Title",
                    description: "Description"
                )
            }
            ImageTextComponent(
                componentSize: .large,
                image: .mosque,
                title: "Title",
                description: "DescriptionDescriptionDescriptionDescriptionDescription"
            )
        }
    }
    
}
