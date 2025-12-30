import SwiftUI

struct CardListView: View {
    @StateObject private var viewModel = CollectionViewModel()
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSearch = false
    @State private var showingStats = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode: String, CaseIterable {
        case list = "list.bullet"
        case grid = "square.grid.2x2"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Stats Header
                    statsHeader

                    if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        // Search Bar
                        searchBar

                        // Cards List/Grid
                        if viewMode == .list {
                            cardListContent
                        } else {
                            cardGridContent
                        }
                    }
                }
            }
            .navigationTitle("My Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingStats = true }) {
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // View mode toggle
                        if !viewModel.isEmpty {
                            Picker("View", selection: $viewMode) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Image(systemName: mode.rawValue)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 80)
                        }

                        // Add card button
                        Button(action: { showingSearch = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $viewModel.showingSortSheet) {
                sortSheet
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                filterSheet
            }
            .fullScreenCover(item: $viewModel.selectedCard) { card in
                FullScreenCardView(card: card)
                    .environmentObject(dataManager)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatBadge(
                icon: "rectangle.stack.fill",
                value: "\(viewModel.totalCards)",
                label: "Cards"
            )

            StatBadge(
                icon: "sparkles",
                value: "\(viewModel.uniqueCards)",
                label: "Unique"
            )

            StatBadge(
                icon: "dollarsign.circle.fill",
                value: viewModel.formattedTotalValue,
                label: "Value"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(white: 0.1).opacity(0.5))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search your collection...", text: $viewModel.searchText)
                    .foregroundColor(.white)

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.15))
            )

            // Filter Button
            Button(action: { viewModel.showingFilterSheet = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.selectedFilter != .all ?
                        Color(red: 0.6, green: 0.4, blue: 0.9) : .gray)
            }

            // Sort Button
            Button(action: { viewModel.showingSortSheet = true }) {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Card List

    private var cardListContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredCards) { card in
                    CardRowView(
                        card: card,
                        onTap: { viewModel.selectCard(card) },
                        onIncrement: { viewModel.incrementQuantity(for: card) },
                        onDecrement: { viewModel.decrementQuantity(for: card) }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.removeCard(card)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.refreshPrices()
        }
    }

    // MARK: - Card Grid

    private var cardGridContent: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.filteredCards) { card in
                    CardGridItem(card: card) {
                        viewModel.selectCard(card)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.removeCard(card)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.refreshPrices()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 70))
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
                Text("Your Collection is Empty")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Start adding cards to track your Magic: The Gathering collection")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: { showingSearch = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Your First Card")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.5, green: 0.3, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            Spacer()
        }
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        NavigationStack {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.selectedSort = option
                        viewModel.showingSortSheet = false
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                                .frame(width: 30)

                            Text(option.rawValue)
                                .foregroundColor(.white)

                            Spacer()

                            if viewModel.selectedSort == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showingSortSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.selectedFilter = option
                        viewModel.showingFilterSheet = false
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(Color.rarityColor(for: option.rawValue.lowercased()))
                                .frame(width: 30)

                            Text(option.rawValue)
                                .foregroundColor(.white)

                            Spacer()

                            if viewModel.selectedFilter == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))

                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CardListView()
        .environmentObject(DataManager.shared)
}
