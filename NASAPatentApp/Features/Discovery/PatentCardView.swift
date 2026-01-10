import SwiftUI

struct PatentCardView: View {
    let patent: Patent
    @EnvironmentObject var patentStore: PatentStore
    @State private var isHovered = false
    @State private var bookmarkScale: CGFloat = 1.0

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
        VStack(alignment: .leading, spacing: 12) {
            // Image or Icon Header with gradient overlay
            ZStack {
                if let imageURL = patent.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderBackground
                        case .empty:
                            placeholderBackground
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        @unknown default:
                            placeholderBackground
                        }
                    }
                } else {
                    placeholderBackground
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Category Badge with gradient
            HStack(spacing: 4) {
                Image(systemName: patent.categoryIcon)
                    .font(.caption2.weight(.semibold))
                Text(patent.category)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(colors: categoryGradient, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())

            // Title
            Text(patent.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Description Preview
            Text(patent.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)

            // Save Button with animation
            HStack {
                if let center = patent.center {
                    Text(center)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        bookmarkScale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            bookmarkScale = 1.0
                        }
                    }
                    toggleSave()
                } label: {
                    Image(systemName: patentStore.isSaved(patent) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(
                            patentStore.isSaved(patent) ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.secondary, .secondary], startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(bookmarkScale)
                }
            }
        }
        .padding()
        .frame(height: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 12 : 8, y: isHovered ? 6 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(colors: categoryGradient.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var placeholderBackground: some View {
        ZStack {
            LinearGradient(
                colors: categoryGradient.map { $0.opacity(0.8) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: patent.categoryIcon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func toggleSave() {
        if patentStore.isSaved(patent) {
            patentStore.removePatent(patent)
        } else {
            patentStore.savePatent(patent)
        }
    }
}

#Preview {
    PatentCardView(patent: Patent(
        id: "1",
        title: "Advanced Composite Materials for Aerospace Applications",
        description: "A novel composite material system designed for extreme temperature environments in aerospace applications.",
        category: "Materials",
        caseNumber: "ARC-14653-2",
        patentNumber: "US9876543",
        imageURL: nil,
        center: "Ames Research Center",
        trl: "6"
    ))
    .environmentObject(PatentStore())
    .frame(width: 180)
    .padding()
}
