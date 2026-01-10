import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var patentStore: PatentStore
    @State private var searchText = ""
    @State private var patents: [Patent] = []
    @State private var isLoading = false
    @State private var selectedCategory: PatentCategory = .all
    @State private var errorMessage: String?
    @State private var hasSearched = false
    @State private var animateStars = false
    @State private var animateGlow = false

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
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateStars = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
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
        VStack(spacing: 20) {
            ZStack {
                // Outer orbit ring
                Circle()
                    .stroke(
                        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animateStars ? 360 : 0))

                // Inner spinning element
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 12, height: 12)
                    .offset(x: 40)
                    .rotationEffect(.degrees(animateStars ? 360 : 0))

                // Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(animateGlow ? 1.1 : 0.9)
            }

            Text("Searching NASA database...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .opacity(animateGlow ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.2), value: animateGlow)
                }
            }
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
            // Hero Section with Space Theme
            ZStack {
                // Deep space background gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.05, blue: 0.15),
                                Color(red: 0.1, green: 0.1, blue: 0.3),
                                Color(red: 0.05, green: 0.15, blue: 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Animated stars layer
                GeometryReader { geo in
                    ForEach(0..<20, id: \.self) { i in
                        Circle()
                            .fill(.white)
                            .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                            .opacity(animateStars ? Double.random(in: 0.4...1.0) : Double.random(in: 0.2...0.6))
                    }
                }

                // Glowing nebula effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: -20)
                    .blur(radius: 20)
                    .scaleEffect(animateGlow ? 1.2 : 1.0)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(0.2), .blue.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                    .offset(x: 60, y: 30)
                    .blur(radius: 15)
                    .scaleEffect(animateGlow ? 1.0 : 1.15)

                // Content overlay
                VStack(spacing: 16) {
                    // NASA-style icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .blue.opacity(0.6), radius: 20)

                        Image(systemName: "atom")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(animateStars ? 360 : 0))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateStars)
                    }

                    Text("NASA Technology Transfer")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("1,400+ Patents Available")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.vertical, 30)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)

            // Main heading
            VStack(spacing: 8) {
                Text("Explore NASA Patents")
                    .font(.title2.bold())

                Text("Discover innovations that could power your next business venture.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Featured button with gradient
            Button {
                Task { await loadFeatured() }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Browse Featured Patents")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
            }
            .buttonStyle(.plain)

            // Quick category buttons
            VStack(spacing: 12) {
                Text("Popular Categories")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    QuickCategoryButton(title: "Robotics", icon: "gearshape.2", gradient: [.orange, .red]) {
                        selectedCategory = .robotics
                        Task { await search() }
                    }
                    QuickCategoryButton(title: "Sensors", icon: "sensor.tag.radiowaves.forward", gradient: [.green, .teal]) {
                        selectedCategory = .sensors
                        Task { await search() }
                    }
                }
                HStack(spacing: 12) {
                    QuickCategoryButton(title: "Materials", icon: "cube", gradient: [.purple, .pink]) {
                        selectedCategory = .materials
                        Task { await search() }
                    }
                    QuickCategoryButton(title: "Software", icon: "desktopcomputer", gradient: [.cyan, .blue]) {
                        selectedCategory = .information
                        Task { await search() }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var patentsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(patents.enumerated()), id: \.element.id) { index, patent in
                NavigationLink(value: patent) {
                    PatentCardView(patent: patent)
                        .opacity(animateStars ? 1 : 0)
                        .offset(y: animateStars ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: animateStars
                        )
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

    private var gradientColors: [Color] {
        if isSelected {
            return [.blue, .purple]
        }
        return [Color(.systemGray5), Color(.systemGray5)]
    }

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
            .background(
                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct QuickCategoryButton: View {
    let title: String
    let icon: String
    var gradient: [Color] = [.blue, .cyan]
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: gradient.first?.opacity(0.4) ?? .blue.opacity(0.4), radius: 6, y: 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    DiscoveryView()
        .environmentObject(PatentStore())
}
