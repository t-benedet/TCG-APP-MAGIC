import SwiftUI

struct CardImageView: View {
    let url: String?
    let size: CardImageSize

    enum CardImageSize {
        case thumbnail
        case medium
        case large
        case fullScreen

        var width: CGFloat {
            switch self {
            case .thumbnail: return 60
            case .medium: return 150
            case .large: return 250
            case .fullScreen: return UIScreen.main.bounds.width - 40
            }
        }

        var height: CGFloat {
            width * 1.4 // Magic card aspect ratio
        }

        var cornerRadius: CGFloat {
            switch self {
            case .thumbnail: return 6
            case .medium: return 10
            case .large: return 14
            case .fullScreen: return 18
            }
        }
    }

    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .empty:
                placeholder
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            case .failure:
                placeholder
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: size == .thumbnail ? 16 : 30))
                            if size != .thumbnail {
                                Text("Failed to load")
                                    .font(.system(size: 12))
                            }
                        }
                        .foregroundColor(.gray)
                    )
            @unknown default:
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.15),
                        Color(white: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Zoomable Image View

struct ZoomableCardImage: View {
    let url: String?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: url ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1.2 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
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
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                }
                            }
                        }
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 40))
                        Text("Failed to load image")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CardImageView(url: nil, size: .thumbnail)
        CardImageView(url: nil, size: .medium)
        CardImageView(url: nil, size: .large)
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
}
