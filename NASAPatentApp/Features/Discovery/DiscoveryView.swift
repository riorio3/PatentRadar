import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var patentStore: PatentStore
    @State private var searchText = ""
    @State private var patents: [Patent] = []
    @State private var isLoading = false
    @State private var selectedCategory: PatentCategory = .all
    @State private var errorMessage: String?
    @State private var hasSearched = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category Pills
                    categoryPills

                    // Content
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if patents.isEmpty && hasSearched {
                        emptyView
                    } else if patents.isEmpty {
                        welcomeView
                    } else {
                        patentsGrid
                    }
                }
                .padding()
            }
            .navigationTitle("Discover Patents")
            .searchable(text: $searchText, prompt: "Search NASA patents...")
            .onSubmit(of: .search) {
                Task { await search() }
            }
            .refreshable {
                await search()
            }
        }
    }

    // MARK: - Views

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PatentCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        Task { await search() }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching NASA database...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await search() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No patents found")
                .font(.headline)
            Text("Try a different search term or category")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Explore NASA Patents")
                .font(.title2.bold())

            Text("Search 1,400+ NASA technologies available for licensing. Find innovations that could power your next business.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await loadFeatured() }
            } label: {
                Label("Browse Featured Patents", systemImage: "star")
            }
            .buttonStyle(.borderedProminent)

            // Quick category buttons
            VStack(spacing: 12) {
                Text("Popular Categories")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    QuickCategoryButton(title: "Robotics", icon: "gearshape.2") {
                        selectedCategory = .robotics
                        Task { await search() }
                    }
                    QuickCategoryButton(title: "Sensors", icon: "sensor.tag.radiowaves.forward") {
                        selectedCategory = .sensors
                        Task { await search() }
                    }
                }
                HStack(spacing: 12) {
                    QuickCategoryButton(title: "Materials", icon: "cube") {
                        selectedCategory = .materials
                        Task { await search() }
                    }
                    QuickCategoryButton(title: "Software", icon: "desktopcomputer") {
                        selectedCategory = .information
                        Task { await search() }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.top, 40)
    }

    private var patentsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(patents) { patent in
                NavigationLink(value: patent) {
                    PatentCardView(patent: patent)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Patent.self) { patent in
            PatentDetailView(patent: patent)
        }
    }

    // MARK: - Actions

    private func search() async {
        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            if searchText.isEmpty {
                patents = try await NASAAPI.shared.browsePatents(category: selectedCategory)
            } else {
                patents = try await NASAAPI.shared.searchPatents(query: searchText)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadFeatured() async {
        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            patents = try await NASAAPI.shared.getFeaturedPatents()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Supporting Views

struct CategoryPill: View {
    let category: PatentCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct QuickCategoryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiscoveryView()
        .environmentObject(PatentStore())
}
