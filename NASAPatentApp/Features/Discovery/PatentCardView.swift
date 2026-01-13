import SwiftUI

struct PatentCardView: View {
    let patent: Patent
    @EnvironmentObject var patentStore: PatentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image or Icon Header
            ZStack {
                if let imageURL = patent.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                        case .failure:
                            placeholderIcon
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderIcon
                        }
                    }
                } else {
                    placeholderIcon
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Category Badge
            HStack {
                Image(systemName: patent.categoryIcon)
                    .font(.caption2)
                Text(patent.category)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(.blue)

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

            // Save Button
            HStack {
                if let center = patent.center {
                    Text(center)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    toggleSave()
                } label: {
                    Image(systemName: patentStore.isSaved(patent) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(patentStore.isSaved(patent) ? .blue : .secondary)
                }
            }
        }
        .padding()
        .frame(height: 280)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private var placeholderIcon: some View {
        Image(systemName: patent.categoryIcon)
            .font(.system(size: 36))
            .foregroundStyle(.blue.opacity(0.6))
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
