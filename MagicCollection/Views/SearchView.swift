import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    // Suggestions
                    if !viewModel.suggestions.isEmpty && viewModel.searchResults.isEmpty {
                        suggestionsView
                    }

                    // Content
                    if viewModel.isLoading && viewModel.searchResults.isEmpty {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        noResultsView
                    } else if viewModel.searchResults.isEmpty {
                        welcomeView
                    } else {
                        resultsView
                    }
                }
            }
            .navigationTitle("Add Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { viewModel.getRandomCard() }) {
                        Image(systemName: "dice.fill")
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                if let card = viewModel.selectedCard {
                    AddCardView(card: card) { quantity, isFoil in
                        viewModel.addCardToCollection(quantity: quantity, isFoil: isFoil)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search cards...", text: $viewModel.searchText)
                .foregroundColor(.white)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.search()
                }
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.fetchAutocomplete()
                }

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.clearSearch() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.12))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button(action: { viewModel.selectSuggestion(suggestion) }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        Text(suggestion)
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if suggestion != viewModel.suggestions.last {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.searchResults) { card in
                    SearchResultRowView(card: card) {
                        viewModel.selectCard(card)
                    }
                }

                if viewModel.hasMoreResults {
                    Button(action: { viewModel.loadMoreResults() }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Load More")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(Color(red: 0.6, green: 0.4, blue: 0.9))
                .scaleEffect(1.5)
            Text("Searching...")
                .foregroundColor(.gray)
            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { viewModel.search() }) {
                Text("Try Again")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.9))
                    )
            }
            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No cards found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            Text("Try a different search term")
                .foregroundColor(.gray)
            Spacer()
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.6, green: 0.4, blue: 0.9),
                            Color(red: 0.4, green: 0.3, blue: 0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Search for Cards")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Find cards by name, set, or type")
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 12) {
                searchTip(icon: "textformat", text: "Search by card name")
                searchTip(icon: "rectangle.stack", text: "Use set: to filter by set")
                searchTip(icon: "paintbrush", text: "Use c: for color (w, u, b, r, g)")
                searchTip(icon: "star.fill", text: "Use r: for rarity")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1))
            )
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func searchTip(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(DataManager.shared)
}
