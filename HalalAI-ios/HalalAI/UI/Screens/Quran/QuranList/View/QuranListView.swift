//
//  QuranListView.swift
//  HalalAI
//

import SwiftUI

struct QuranListView: View {
    @Environment(Coordinator.self) var coordinator
    @Bindable var viewModel: ViewModel

    var body: some View {
        Group {
            if let msg = viewModel.errorMessage {
                ErrorView(message: msg)
            } else if viewModel.isLoading {
                ProgressView("Загрузка Корана…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                listContent
            }
        }
        .navigationTitle("Коран")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadQuran() }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.quranStorage.lastReadSuraIndex != nil, viewModel.quranStorage.lastReadVerseNumber != nil {
                    continueReadingButton
                }
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.suras) { sura in
                        suraRow(sura)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var continueReadingButton: some View {
        Button {
            if let idx = viewModel.quranStorage.lastReadSuraIndex,
               let sura = viewModel.suras.first(where: { $0.index == idx }) {
                coordinator.nextStep(step: .Home(.sura(suraIndex: idx)))
            }
        } label: {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Продолжить чтение")
                        .font(.headline)
                    if let s = viewModel.quranStorage.lastReadSuraIndex,
                       let name = viewModel.suras.first(where: { $0.index == s })?.displayTitle {
                        Text("Сура \(name)")
                            .font(.subheadline)
                            .opacity(0.9)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.greenForeground.opacity(0.3)))
            .foregroundColor(.darkGreen)
        }
        .buttonStyle(.plain)
    }

    private func suraRow(_ sura: Sura) -> some View {
        Button {
            coordinator.nextStep(step: .Home(.sura(suraIndex: sura.index)))
        } label: {
            HStack {
                Text("\(sura.index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.greenForeground.opacity(0.5)))
                    .foregroundColor(.darkGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sura.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.darkGreen)
                    Text(sura.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(sura.verses.count) аятов")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.greenForeground.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }
}
