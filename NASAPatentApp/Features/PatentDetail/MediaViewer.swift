import SwiftUI
import AVKit
import WebKit

// MARK: - Full Screen Zoomable Image Viewer

struct FullScreenImageViewer: View {
    let images: [String]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, urlString in
                    ZoomableImageView(urlString: urlString)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()

                // Image counter
                if images.count > 1 {
                    Text("\(selectedIndex + 1) / \(images.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Zoomable Single Image

struct ZoomableImageView: View {
    let urlString: String

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geo in
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .contentShape(Rectangle())
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale = min(max(scale * delta, minScale), maxScale)
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if scale < minScale {
                                                    scale = minScale
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1 {
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                clampOffset(in: geo.size)
                                            }
                                        }
                                )
                            )
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if scale > 1.0 {
                                                scale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                scale = 3.0
                                            }
                                        }
                                    }
                            )
                    case .failure:
                        imagePlaceholder
                            .frame(width: geo.size.width, height: geo.size.height)
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .frame(width: geo.size.width, height: geo.size.height)
                    @unknown default:
                        imagePlaceholder
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
        }
    }

    private func clampOffset(in size: CGSize) {
        guard scale > 1 else {
            offset = .zero
            lastOffset = .zero
            return
        }
        let maxX = (size.width * (scale - 1)) / 2
        let maxY = (size.height * (scale - 1)) / 2
        offset.width = min(max(offset.width, -maxX), maxX)
        offset.height = min(max(offset.height, -maxY), maxY)
        lastOffset = offset
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 40))
            Text("Image unavailable")
                .font(.caption)
        }
        .foregroundStyle(.gray)
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let videoURL: String
    @Binding var isPresented: Bool

    private var isYouTube: Bool {
        videoURL.contains("youtube.com") || videoURL.contains("youtu.be")
    }

    private var parsedURL: URL? {
        if let url = URL(string: videoURL) {
            return url
        }
        if let encoded = videoURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            return url
        }
        return nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = parsedURL {
                if isYouTube {
                    // Use WebView for YouTube
                    YouTubePlayerView(url: url, isPresented: $isPresented)
                } else {
                    // Use native AVPlayer for direct video URLs
                    NativeVideoPlayerView(url: url, isPresented: $isPresented)
                }
            } else {
                errorView
            }

            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Unable to Play Video")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("The video URL could not be loaded")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Button("Close") {
                isPresented = false
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Native AVPlayer Video View

struct NativeVideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.delegate = context.coordinator

        // Auto-play
        player.play()

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Cleanup when view is being dismissed
        if !isPresented {
            uiViewController.player?.pause()
            uiViewController.player = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // Clean up when dismissing
            playerViewController.player?.pause()
            playerViewController.player = nil
            isPresented = false
        }
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        // Final cleanup when view is destroyed
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}

// MARK: - YouTube WebView Player

struct YouTubePlayerView: UIViewRepresentable {
    let url: URL
    @Binding var isPresented: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        // Convert watch URL to embed URL for better playback
        let embedURL = convertToEmbedURL(url)
        let request = URLRequest(url: embedURL)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Stop loading and clear content when dismissed
        if !isPresented {
            uiView.stopLoading()
            uiView.loadHTMLString("", baseURL: nil)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: ()) {
        // Final cleanup when view is destroyed
        uiView.stopLoading()
        uiView.loadHTMLString("", baseURL: nil)
    }

    private func convertToEmbedURL(_ url: URL) -> URL {
        let urlString = url.absoluteString

        // Extract video ID
        var videoID: String?
        if urlString.contains("youtube.com/watch?v=") {
            videoID = urlString.components(separatedBy: "v=").last?.components(separatedBy: "&").first
        } else if urlString.contains("youtu.be/") {
            videoID = urlString.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        } else if urlString.contains("youtube.com/embed/") {
            return url // Already an embed URL
        }

        if let id = videoID {
            // Create embed URL with autoplay
            return URL(string: "https://www.youtube.com/embed/\(id)?autoplay=1&playsinline=1") ?? url
        }

        return url
    }
}


// MARK: - Video Thumbnail

struct VideoThumbnailView: View {
    let videoURL: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isYouTubeURL(videoURL), let thumbnailURL = youTubeThumbnailURL(videoURL) {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            videoPlaceholder
                        }
                    }
                } else {
                    videoPlaceholder
                }

                // Play button overlay
                Circle()
                    .fill(.black.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    )

                // YouTube badge
                if isYouTubeURL(videoURL) {
                    VStack {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.red)
                                .padding(6)
                                .background(.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var videoPlaceholder: some View {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            VStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 40))
                Text("Video")
                    .font(.caption)
            }
            .foregroundStyle(.blue)
        )
    }

    private func isYouTubeURL(_ url: String) -> Bool {
        url.contains("youtube.com") || url.contains("youtu.be")
    }

    private func youTubeThumbnailURL(_ url: String) -> URL? {
        var videoID: String?

        if url.contains("youtube.com/watch?v=") {
            videoID = url.components(separatedBy: "v=").last?.components(separatedBy: "&").first
        } else if url.contains("youtu.be/") {
            videoID = url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }

        guard let id = videoID else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }
}
