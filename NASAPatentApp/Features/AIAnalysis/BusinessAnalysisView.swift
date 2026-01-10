import SwiftUI

struct BusinessAnalysisView: View {
    let analysis: BusinessAnalysis
    let patent: Patent
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var appearAnimation = false

    private let tabGradients: [[Color]] = [
        [.yellow, .orange],      // Ideas
        [.blue, .cyan],          // Markets
        [.red, .pink],           // Competition
        [.purple, .indigo],      // Roadmap
        [.green, .mint]          // Costs
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tab Selector
                    tabSelector

                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case 0:
                            businessIdeasSection
                        case 1:
                            marketsSection
                        case 2:
                            competitionSection
                        case 3:
                            roadmapSection
                        case 4:
                            costsSection
                        default:
                            businessIdeasSection
                        }
                    }
                    .padding(.horizontal)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Business Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    appearAnimation = true
                }
            }
            .onChange(of: selectedTab) { _, _ in
                appearAnimation = false
                withAnimation(.easeOut(duration: 0.3)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                AnalysisTabButton(title: "Ideas", icon: "lightbulb.fill", isSelected: selectedTab == 0, gradient: tabGradients[0]) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
                AnalysisTabButton(title: "Markets", icon: "chart.pie.fill", isSelected: selectedTab == 1, gradient: tabGradients[1]) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
                AnalysisTabButton(title: "Competition", icon: "person.3.fill", isSelected: selectedTab == 2, gradient: tabGradients[2]) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
                AnalysisTabButton(title: "Roadmap", icon: "map.fill", isSelected: selectedTab == 3, gradient: tabGradients[3]) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 3
                    }
                }
                AnalysisTabButton(title: "Costs", icon: "dollarsign.circle.fill", isSelected: selectedTab == 4, gradient: tabGradients[4]) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 4
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Business Ideas

    private var businessIdeasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Business Ideas",
                subtitle: "Potential products and services",
                icon: "lightbulb.fill",
                gradient: [.yellow, .orange]
            )

            ForEach(analysis.businessIdeas) { idea in
                BusinessIdeaCard(idea: idea)
            }
        }
    }

    // MARK: - Markets

    private var marketsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Target Markets",
                subtitle: "Industries and customer segments",
                icon: "chart.pie.fill",
                gradient: [.blue, .cyan]
            )

            ForEach(Array(analysis.targetMarkets.enumerated()), id: \.offset) { index, market in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue.opacity(0.2), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "target")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    Text(market)
                        .font(.subheadline.weight(.medium))

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
            }

            // Revenue Models
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Text("Revenue Models")
                        .font(.headline)
                }
                .padding(.top, 8)

                ForEach(Array(analysis.revenueModels.enumerated()), id: \.offset) { index, model in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 28, height: 28)

                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        }

                        Text(model)
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.08))
                    )
                }
            }
        }
    }

    // MARK: - Competition

    private var competitionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Competition Analysis",
                subtitle: "Existing players and your advantages",
                icon: "person.3.fill",
                gradient: [.red, .pink]
            )

            ForEach(analysis.competition) { competitor in
                CompetitorCard(competitor: competitor)
            }
        }
    }

    // MARK: - Roadmap

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Implementation Roadmap",
                subtitle: "Steps to bring this to market",
                icon: "map.fill",
                gradient: [.purple, .indigo]
            )

            ForEach(analysis.roadmap) { step in
                RoadmapStepCard(step: step)
            }
        }
    }

    // MARK: - Costs

    private var costsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Cost Estimates",
                subtitle: "Budget ranges for commercialization",
                icon: "dollarsign.circle.fill",
                gradient: [.green, .mint]
            )

            CostRow(title: "Prototyping", value: analysis.costEstimates.prototyping, icon: "hammer")
            CostRow(title: "Manufacturing", value: analysis.costEstimates.manufacturing, icon: "building.2")
            CostRow(title: "Marketing", value: analysis.costEstimates.marketing, icon: "megaphone")

            Divider()

            HStack {
                Text("Estimated Total")
                    .font(.headline)
                Spacer()
                Text(analysis.costEstimates.total)
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Startup NASA callout
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Startup NASA Program")
                        .font(.headline)
                }

                Text("Eligible startups can license this technology for FREE for up to 3 years, significantly reducing initial costs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://technology.nasa.gov/startup")!) {
                    Text("Learn More")
                        .font(.subheadline.bold())
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Supporting Views

struct AnalysisTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var gradient: [Color] = [.blue, .cyan]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: gradient.first?.opacity(0.5) ?? .blue.opacity(0.5), radius: 6, y: 2)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                .frame(width: 36, height: 36)

                Text(title)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? gradient.first ?? .blue : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? gradient.first?.opacity(0.1) ?? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? gradient.first?.opacity(0.3) ?? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    var icon: String = "sparkles"
    var gradient: [Color] = [.blue, .purple]

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: gradient.first?.opacity(0.4) ?? .blue.opacity(0.4), radius: 6, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }
}

struct BusinessIdeaCard: View {
    let idea: BusinessIdea
    @State private var isExpanded = false

    var scaleGradient: [Color] {
        switch idea.potentialScale.lowercased() {
        case "large": return [.green, .mint]
        case "medium": return [.orange, .yellow]
        default: return [.blue, .cyan]
        }
    }

    var scaleIcon: String {
        switch idea.potentialScale.lowercased() {
        case "large": return "arrow.up.right.circle.fill"
        case "medium": return "circle.circle.fill"
        default: return "arrow.right.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: scaleGradient.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(colors: scaleGradient, startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(idea.name)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: scaleIcon)
                            .font(.caption)
                        Text(idea.potentialScale + " Scale")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(scaleGradient.first ?? .blue)
                }

                Spacer()
            }

            Text(idea.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 3)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "Show less" : "Read more")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(scaleGradient.first ?? .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(colors: scaleGradient.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

struct CompetitorCard: View {
    let competitor: CompetitorInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.red.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(colors: [.red, .pink], startPoint: .top, endPoint: .bottom)
                        )
                }

                Text(competitor.name)
                    .font(.headline)

                Spacer()
            }

            Text(competitor.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Advantage section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Your Advantage")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }

                Text(competitor.gap)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RoadmapStepCard: View {
    let step: RoadmapStep

    private var stepGradient: [Color] {
        switch step.step {
        case 1: return [.purple, .indigo]
        case 2: return [.indigo, .blue]
        case 3: return [.blue, .cyan]
        case 4: return [.cyan, .teal]
        case 5: return [.teal, .green]
        default: return [.purple, .indigo]
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number with gradient
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: stepGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: stepGradient.first?.opacity(0.4) ?? .purple.opacity(0.4), radius: 6, y: 2)

                    Text("\(step.step)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                // Connector line
                if step.step < 5 {
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [stepGradient.last ?? .purple, .clear], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 2, height: 30)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.headline)

                Text(step.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(colors: stepGradient.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

struct CostRow: View {
    let title: String
    let value: String
    let icon: String

    private var iconColor: Color {
        switch icon {
        case "hammer": return .orange
        case "building.2": return .blue
        case "megaphone": return .purple
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline.weight(.medium))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6).opacity(0.6))
        )
    }
}

#Preview {
    BusinessAnalysisView(
        analysis: BusinessAnalysis(
            patentId: "1",
            businessIdeas: [
                BusinessIdea(name: "Thermal Protection Kits", description: "Consumer-grade thermal protection for outdoor equipment", potentialScale: "Medium"),
                BusinessIdea(name: "Industrial Insulation", description: "High-temp insulation for manufacturing facilities", potentialScale: "Large")
            ],
            targetMarkets: ["Aerospace Industry", "Automotive", "Consumer Electronics"],
            competition: [
                CompetitorInfo(name: "3M Thermal Products", description: "Industrial thermal solutions", gap: "NASA tech handles 40% higher temperatures")
            ],
            revenueModels: ["Product Sales", "Licensing to Manufacturers"],
            roadmap: [
                RoadmapStep(step: 1, title: "Prototype Development", description: "Create initial prototypes using NASA specs"),
                RoadmapStep(step: 2, title: "Testing & Certification", description: "Industry standard testing"),
                RoadmapStep(step: 3, title: "Manufacturing Setup", description: "Partner with manufacturer")
            ],
            costEstimates: CostEstimate(prototyping: "$50K - $100K", manufacturing: "$200K - $500K", marketing: "$50K - $100K", total: "$300K - $700K")
        ),
        patent: Patent(
            id: "1",
            title: "Advanced Composite Materials",
            description: "High-temp materials",
            category: "Materials",
            caseNumber: "ARC-123",
            patentNumber: nil,
            imageURL: nil,
            center: "Ames",
            trl: "6"
        )
    )
}
