import SwiftUI

struct MotivationalQuotesSectionView: View {
    @ObservedObject var settings: TakeABreakSettings
    @State private var newMotivationalQuote: String = ""
    @State private var showResetAlert = false
    @State private var isShowingAddQuoteSheet = false

    var body: some View {
        Section {
            VStack(spacing: 16) {                
                if settings.motivationalQuotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No motivational quotes yet")
                            .font(.headline)
                        Text("Add your first quote to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(settings.motivationalQuotes.indices, id: \.self) { index in
                                HStack(alignment: .center, spacing: 12) {
                                    Text(settings.motivationalQuotes[index])
                                        .lineLimit(3)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    
                                    Spacer()
                                    
                                    Button {
                                        deleteQuote(at: IndexSet(integer: index))
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary.opacity(0.7))
                                            .font(.system(size: 16))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 250)
                }
                
                // Button row at the bottom
                HStack {
                    Spacer()
                    
                    Button {
                        newMotivationalQuote = ""
                        isShowingAddQuoteSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .help("Add new quote")
                    
                    Button(action: { showResetAlert = true }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Reset to default quotes")
                }
                .padding(.top, 4)
            }
        } header: {
            DetailedSectionHeader(
                title: "Motivational Quotes",
                subtitle: "Personalize with your favorite quotes",
                systemName: "quote.bubble.fill",
                themeColor: .purple
            )
        }
        .alert("Reset Motivational Quotes", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetMotivationalQuotes()
            }
        } message: {
            Text("This will restore the default motivational quotes and remove all custom quotes. Are you sure?")
        }
        .sheet(isPresented: $isShowingAddQuoteSheet) {
            AddQuoteSheetView(
                newMotivationalQuote: $newMotivationalQuote,
                onSave: { quoteText in
                    addQuote()
                    isShowingAddQuoteSheet = false
                },
                onCancel: {
                    isShowingAddQuoteSheet = false
                }
            )
        }
    }

    private func addQuote() {
        let trimmedQuote = newMotivationalQuote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuote.isEmpty {
            withAnimation {
                settings.motivationalQuotes.append(trimmedQuote)
            }
            newMotivationalQuote = "" 
        }
    }

    private func deleteQuote(at offsets: IndexSet) {
        withAnimation {
            settings.motivationalQuotes.remove(atOffsets: offsets)
        }
    }
}

struct AddQuoteSheetView: View {
    @Binding var newMotivationalQuote: String
    var onSave: (String) -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private let textEditorMinHeight: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Motivational Quote")
                    .font(.title3.weight(.medium))
                Spacer()
            }
            .padding()

            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter an inspiring message that will be shown during breaks:")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $newMotivationalQuote)
                        .font(.body)
                        .padding(EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5))
                        .frame(minHeight: textEditorMinHeight, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        .scrollContentBackground(.hidden)

                    if newMotivationalQuote.isEmpty {
                        Text("Type something inspiring here...")
                            .font(.body)
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                            .padding(.init(top: 8, leading: 5, bottom: 8, trailing: 5))
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            
            HStack(spacing: 12) {
                Spacer()
                Button("Cancel", role: .cancel) {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Quote") {
                    let trimmedQuote = newMotivationalQuote.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedQuote.isEmpty {
                        onSave(trimmedQuote)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newMotivationalQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .background(.ultraThickMaterial)
    }
}