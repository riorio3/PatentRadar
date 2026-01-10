import SwiftUI

struct PatentDetailView: View {
    let patent: Patent
    @EnvironmentObject var patentStore: PatentStore
    @State private var showAnalysis = false
    @State private var analysis: BusinessAnalysis?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var animateGradient = false
    @State private var trlAnimated = false

    private var categoryGradient: [Color] {
        switch patent.category.lowercased() {
        case let c where c.contains("aero"): return [.blue, .cyan]
        case let c where c.contains("propulsion"): return [.orange, .red]
        case let c where c.contains("material"): return [.purple, .pink]
        case let c where c.contains("sensor"): return [.green, .teal]
        case let c where c.contains("robot"): return [.orange, .yellow]
        case let c where c.contains("software"), let c where c.contains("information"): return [.cyan, .blue]
        case let c where c.contains("power"), let c where c.contains("energy"): return [.yellow, .orange]
        case let c where c.contains("health"): return [.red, .pink]
        case let c where c.contains("environment"): return [.green, .mint]
        default: return [.blue, .purple]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image
                headerImage

                VStack(alignment: .leading, spacing: 20) {
                    // Title & Category
                    titleSection

                    // Quick Stats
                    statsRow

                    Divider()

                    // Description
                    descriptionSection

                    Divider()

                    // AI Analysis CTA
                    analysisSection

                    Divider()

                    // Licensing Info
                    licensingSection

                    // Links
                    linksSection
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Patent Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleSave()
                } label: {
                    Image(systemName: patentStore.isSaved(patent) ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .sheet(isPresented: $showAnalysis) {
            if let analysis = analysis {
                BusinessAnalysisView(analysis: analysis, patent: patent)
            }
        }
    }

    // MARK: - Views

    private var headerImage: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: animateGradient ? categoryGradient : categoryGradient.reversed(),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)

            if let imageURL = patent.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    case .failure:
                        headerPlaceholder
                    case .empty:
                        headerPlaceholder
                            .overlay(ProgressView().tint(.white))
                    @unknown default:
                        headerPlaceholder
                    }
                }
            } else {
                headerPlaceholder
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear {
            animateGradient = true
        }
    }

    private var headerPlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: patent.categoryIcon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(.white)
            }

            Text("NASA Technology")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patent.categoryIcon)
                Text(patent.category)
            }
            .font(.subheadline)
            .foregroundStyle(.blue)

            Text(patent.title)
                .font(.title2.bold())
        }
    }

    private var statsRow: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatItem(
                    icon: "building.columns",
                    label: "Center",
                    value: patent.center ?? "NASA",
                    gradient: [.blue, .cyan]
                )

                StatItem(
                    icon: "doc.text",
                    label: "Case",
                    value: patent.caseNumber.isEmpty ? "N/A" : String(patent.caseNumber.prefix(12)),
                    gradient: [.purple, .pink]
                )
            }

            // Visual TRL Indicator
            if let trl = patent.trl, let trlValue = Int(trl) {
                TRLProgressView(level: trlValue, animated: trlAnimated)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.8)) {
                                trlAnimated = true
                            }
                        }
                    }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)

            Text(patent.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Business Potential")
                    .font(.headline)
            }

            if let error = analysisError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if error.contains("API key") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Text("Add API Key in Settings")
                            .font(.subheadline)
                    }
                }
            }

            Button {
                Task { await analyzePatent() }
            } label: {
                HStack(spacing: 10) {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    Text(isAnalyzing ? "Analyzing Patent..." : "Analyze with AI")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isAnalyzing ? [.gray, .gray.opacity(0.8)] : [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: isAnalyzing ? .clear : .purple.opacity(0.4), radius: 10, y: 5)
            }
            .disabled(isAnalyzing)
            .scaleEffect(isAnalyzing ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isAnalyzing)

            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text("Get AI-powered business ideas, market analysis, and implementation roadmap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    private var licensingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Licensing Options")
                .font(.headline)

            VStack(spacing: 12) {
                LicenseOptionRow(
                    title: "Startup NASA",
                    description: "Free for startups - up to 3 years",
                    icon: "star",
                    highlight: true
                )

                LicenseOptionRow(
                    title: "Research License",
                    description: "12-month development & testing",
                    icon: "flask",
                    highlight: false
                )

                LicenseOptionRow(
                    title: "Commercial License",
                    description: "Full manufacturing rights",
                    icon: "building.2",
                    highlight: false
                )
            }

            if let licenseURL = URL(string: "https://technology.nasa.gov/license") {
                Link(destination: licenseURL) {
                    HStack {
                        Text("Start Licensing Application")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Information")
                .font(.headline)

            if let usptoURL = patent.usptoURL {
                Link(destination: usptoURL) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View Full Patent (USPTO)")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.blue)
                }
            }

            if let portalURL = URL(string: "https://technology.nasa.gov/patent/\(patent.id)") {
                Link(destination: portalURL) {
                    HStack {
                        Image(systemName: "globe")
                        Text("View on NASA T2 Portal")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func toggleSave() {
        if patentStore.isSaved(patent) {
            patentStore.removePatent(patent)
        } else {
            patentStore.savePatent(patent)
        }
    }

    private func analyzePatent() async {
        isAnalyzing = true
        analysisError = nil

        do {
            analysis = try await AIService.shared.analyzePatent(patent)
            showAnalysis = true
        } catch {
            analysisError = error.localizedDescription
        }

        isAnalyzing = false
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    var gradient: [Color] = [.blue, .cyan]

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient.map { $0.opacity(0.15) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - TRL Progress View

struct TRLProgressView: View {
    let level: Int
    let animated: Bool

    private let maxTRL = 9

    private var trlColor: Color {
        switch level {
        case 1...3: return .orange
        case 4...6: return .blue
        case 7...9: return .green
        default: return .gray
        }
    }

    private var trlDescription: String {
        switch level {
        case 1: return "Basic principles observed"
        case 2: return "Technology concept formulated"
        case 3: return "Experimental proof of concept"
        case 4: return "Technology validated in lab"
        case 5: return "Technology validated in environment"
        case 6: return "Technology demonstrated"
        case 7: return "System prototype demonstration"
        case 8: return "System complete and qualified"
        case 9: return "Actual system proven"
        default: return "Technology Readiness Level"
        }
    }

    private var readinessLabel: String {
        switch level {
        case 1...3: return "Research"
        case 4...6: return "Development"
        case 7...9: return "Deployment Ready"
        default: return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(trlColor)
                Text("Technology Readiness Level")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(readinessLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(trlColor)
                    .clipShape(Capsule())
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // Filled progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [trlColor, trlColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animated ? geometry.size.width * (CGFloat(level) / CGFloat(maxTRL)) : 0, height: 12)

                    // Level markers
                    HStack(spacing: 0) {
                        ForEach(1...maxTRL, id: \.self) { i in
                            Circle()
                                .fill(i <= level ? trlColor : Color(.systemGray4))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 1.5)
                                )
                            if i < maxTRL {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .frame(height: 12)

            // Level labels
            HStack {
                Text("TRL 1")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("TRL \(level)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(trlColor)
                Spacer()
                Text("TRL 9")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(trlDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct LicenseOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let highlight: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(highlight ? .yellow : .blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if highlight {
                Text("FREE")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(highlight ? Color.blue.opacity(0.05) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        PatentDetailView(patent: Patent(
            id: "1",
            title: "Advanced Composite Materials for Aerospace Applications",
            description: "A novel composite material system designed for extreme temperature environments in aerospace applications. This technology enables lightweight structures that can withstand temperatures exceeding 2000 degrees Fahrenheit while maintaining structural integrity.",
            category: "Materials",
            caseNumber: "ARC-14653-2",
            patentNumber: "US9876543",
            imageURL: nil,
            center: "Ames Research Center",
            trl: "6"
        ))
        .environmentObject(PatentStore())
    }
}
