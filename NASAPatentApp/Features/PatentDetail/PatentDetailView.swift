import SwiftUI

struct PatentDetailView: View {
    let patent: Patent
    @EnvironmentObject var patentStore: PatentStore
    @State private var enrichedPatent: Patent?
    @State private var isLoadingDetails = true
    @State private var showAnalysis = false
    @State private var analysis: BusinessAnalysis?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var selectedImageIndex = 0

    private var currentPatent: Patent {
        enrichedPatent ?? patent
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image Gallery
                imageGallery

                VStack(alignment: .leading, spacing: 20) {
                    // Title & Category
                    titleSection

                    // Quick Stats
                    statsRow

                    // Patent Numbers (if available)
                    if let patentNumbers = currentPatent.patentNumbers, !patentNumbers.isEmpty {
                        patentNumbersSection(patentNumbers)
                    }

                    Divider()

                    // Description
                    descriptionSection

                    // Benefits (if available)
                    if let benefits = currentPatent.benefits, !benefits.isEmpty {
                        Divider()
                        benefitsSection(benefits)
                    }

                    // Applications (if available)
                    if let applications = currentPatent.applications, !applications.isEmpty {
                        Divider()
                        applicationsSection(applications)
                    }

                    Divider()

                    // AI Analysis CTA
                    analysisSection

                    Divider()

                    // Licensing Info
                    licensingSection

                    // Related Technologies (if available)
                    if let related = currentPatent.relatedTechnologies, !related.isEmpty {
                        Divider()
                        relatedTechnologiesSection(related)
                    }

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
                BusinessAnalysisView(analysis: analysis, patent: currentPatent)
            }
        }
        .task {
            await loadExtendedDetails()
        }
    }

    // MARK: - Views

    private var imageGallery: some View {
        ZStack {
            let images = currentPatent.allImages
            if images.isEmpty {
                headerPlaceholder
            } else if images.count == 1 {
                singleImage(url: images[0])
            } else {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, imageURL in
                        singleImage(url: imageURL)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }

            // Loading indicator overlay
            if isLoadingDetails {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading details...")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(8)
                    .background(.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipped()
    }

    private func singleImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                headerPlaceholder
            case .empty:
                ProgressView()
            @unknown default:
                headerPlaceholder
            }
        }
    }

    private var headerPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: currentPatent.categoryIcon)
                .font(.system(size: 60))
            Text("NASA Technology")
                .font(.caption)
        }
        .foregroundStyle(.blue)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: currentPatent.categoryIcon)
                Text(currentPatent.category)
            }
            .font(.subheadline)
            .foregroundStyle(.blue)

            Text(currentPatent.title)
                .font(.title2.bold())
        }
    }

    private var statsRow: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "building.columns",
                label: "Center",
                value: currentPatent.center ?? "NASA"
            )

            if let trl = currentPatent.trl {
                StatItem(
                    icon: "chart.bar",
                    label: "TRL",
                    value: trl
                )
            }

            StatItem(
                icon: "doc.text",
                label: "Case",
                value: currentPatent.caseNumber.isEmpty ? "N/A" : String(currentPatent.caseNumber.prefix(12))
            )
        }
    }

    private func patentNumbersSection(_ numbers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.badge.gearshape")
                    .foregroundStyle(.blue)
                Text("USPTO Patents")
                    .font(.subheadline.weight(.medium))
            }

            FlowLayout(spacing: 8) {
                ForEach(numbers, id: \.self) { number in
                    if let url = URL(string: "https://patents.google.com/patent/US\(number)") {
                        Link(destination: url) {
                            Text("US\(number)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    } else {
                        Text("US\(number)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.blue)
                Text("Description")
                    .font(.headline)
            }

            Text(currentPatent.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func benefitsSection(_ benefits: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Benefits")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .padding(.top, 3)
                        Text(benefit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func applicationsSection(_ applications: [PatentApplication]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.orange)
                Text("Applications")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(applications) { app in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.domain)
                            .font(.subheadline.weight(.medium))
                        if !app.description.isEmpty {
                            Text(app.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
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
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Analyze with AI")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isAnalyzing)

            Text("Get AI-powered business ideas, market analysis, and an implementation roadmap")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var licensingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "signature")
                    .foregroundStyle(.blue)
                Text("Licensing Options")
                    .font(.headline)
            }

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

    private func relatedTechnologiesSection(_ related: [RelatedTechnology]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.blue)
                Text("Related Technologies")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(related) { tech in
                        NavigationLink {
                            // Create a minimal patent for navigation
                            PatentDetailView(patent: Patent(
                                id: tech.id,
                                title: tech.title,
                                description: "",
                                category: "",
                                caseNumber: tech.caseNumber,
                                patentNumber: nil,
                                imageURL: tech.imageURL,
                                center: nil,
                                trl: nil,
                                benefits: nil,
                                applications: nil,
                                patentNumbers: nil,
                                caseNumbers: nil,
                                imageURLs: nil,
                                relatedTechnologies: nil,
                                detailLoaded: false
                            ))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(tech.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(tech.caseNumber)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle")
                    .foregroundStyle(.blue)
                Text("More Information")
                    .font(.headline)
            }

            if let usptoURL = currentPatent.usptoURL {
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

            if let portalURL = URL(string: "https://technology.nasa.gov/patent/\(currentPatent.caseNumber)") {
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

    private func loadExtendedDetails() async {
        guard !patent.detailLoaded else {
            isLoadingDetails = false
            return
        }

        do {
            let detailed = try await NASAAPI.shared.fetchPatentDetails(for: patent)
            await MainActor.run {
                enrichedPatent = detailed
                isLoadingDetails = false
            }
        } catch {
            await MainActor.run {
                isLoadingDetails = false
            }
        }
    }

    private func toggleSave() {
        if patentStore.isSaved(patent) {
            patentStore.removePatent(patent)
        } else {
            patentStore.savePatent(currentPatent)
        }
    }

    private func analyzePatent() async {
        isAnalyzing = true
        analysisError = nil

        do {
            analysis = try await AIService.shared.analyzePatent(currentPatent)
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

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        PatentDetailView(patent: Patent(
            id: "1",
            title: "Advanced Composite Materials for Aerospace Applications",
            description: "A novel composite material system designed for extreme temperature environments in aerospace applications. This technology enables lightweight structures that can withstand temperatures exceeding 2000 degrees Fahrenheit while maintaining structural integrity.",
            category: "Materials",
            caseNumber: "LAR-TOPS-95",
            patentNumber: "US9876543",
            imageURL: nil,
            center: "Langley Research Center",
            trl: "6",
            benefits: ["High temperature resistance", "Lightweight design", "Superior strength"],
            applications: [PatentApplication(domain: "Aerospace", description: "Aircraft structures")],
            patentNumbers: ["9876543", "8765432"],
            caseNumbers: nil,
            imageURLs: nil,
            relatedTechnologies: nil,
            detailLoaded: true
        ))
        .environmentObject(PatentStore())
    }
}
