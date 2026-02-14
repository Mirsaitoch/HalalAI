//
//  SuraReaderView.swift
//  HalalAI
//


import SwiftUI

struct SuraReaderView: View {
    @Environment(Coordinator.self) var coordinator
    @State var viewModel: ViewModel

    var body: some View {
        Group {
            if let s = viewModel.sura {
                readerContent(sura: s)
            } else {
                ProgressView("Загрузка…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "arrow.left")
                    .onTapGesture {
                        coordinator.dismiss()
                    }
            }
        }
        .navigationTitle(viewModel.sura?.displayTitle ?? "Сура")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.greenBackground.ignoresSafeArea())
        .onAppear { viewModel.loadSura() }
        .onDisappear { viewModel.saveProgressIfNeeded() }
    }

    private func readerContent(sura: Sura) -> some View {
        VStack(spacing: 0) {
            fontControls
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(sura.verses.enumerated()), id: \.element.id) { index, verse in
                        verseRow(verse: verse, sura: sura)
                            .id(verse.id)
                            .onAppear { viewModel.trackVisibleVerse(suraIndex: sura.index, verseNumber: verse.verseNumber ?? index + 1) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }

    private var fontControls: some View {
        HStack {
            Text("Размер текста")
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: $viewModel.fontSize, in: 14...28, step: 1)
                .tint(Color.greenForeground)
            Text("\(Int(viewModel.fontSize))")
                .font(.caption)
                .frame(width: 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.greenForeground.opacity(0.15))
    }

    private func verseRow(verse: QuranVerse, sura: Sura) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let num = verse.verseNumber {
                Text("\(num)")
                    .font(.system(size: viewModel.fontSize * 0.7, weight: .medium))
                    .foregroundColor(.greenForeground)
                    .frame(width: 24, alignment: .trailing)
            }
            Text(verse.text)
                .font(.system(size: viewModel.fontSize))
                .foregroundColor(.darkGreen)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
