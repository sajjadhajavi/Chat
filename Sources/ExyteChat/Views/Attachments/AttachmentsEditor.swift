//
//  AttachmentsEditor.swift
//  Chat
//
//  Created by Alex.M on 22.06.2022.
//

import SwiftUI
import ExyteMediaPicker
import ActivityIndicatorView
import SHAssetToolkit

struct AttachmentsEditor<InputViewContent: View>: View {
    
    typealias InputViewBuilderClosure = ChatView<EmptyView, InputViewContent, DefaultMessageMenuAction>.InputViewBuilderClosure
    
    @Environment(\.chatTheme) var theme
    @Environment(\.mediaPickerTheme) var mediaPickerTheme
    @Environment(\.mediaPickerThemeIsOverridden) var mediaPickerThemeIsOverridden
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var keyboardState: KeyboardState
    @EnvironmentObject private var globalFocusState: GlobalFocusState

    @ObservedObject var inputViewModel: InputViewModel

    var inputViewBuilder: InputViewBuilderClosure?
    var chatTitle: String?
    var messageStyler: (String) -> AttributedString
    var orientationHandler: MediaPickerOrientationHandler
    var mediaPickerSelectionParameters: MediaPickerParameters?
    var availableInputs: [AvailableInputType]
    var localization: ChatLocalization

    @State private var seleсtedMedias: [Media] = []
    @State private var currentFullscreenMedia: Media?
    @State private var inputViewHeight: CGFloat = 0

    var showingAlbums: Bool {
        inputViewModel.mediaPickerMode == .albums
    }

    var body: some View {
        ZStack {
            mediaPicker

            if inputViewModel.showActivityIndicator {
                ActivityIndicator()
            }
        }
    }
    @State private var mediaItems: [MediaItemWithURL] = []

    var mediaPicker: some View {
        GeometryReader { g in
            VStack {
                if !seleсtedMedias.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(mediaItems, id: \.media.id) { item in
                                Group {
                                    if item.media.type == .video {
                                        SHVideoPlayerView(url: item.url.absoluteString, isPortrait: .constant(false))
                                    } else {
                                        if let uiImage = UIImage(contentsOfFile: item.url.path) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFit()
                                        }
                                    }
                                }
                                .id(item.media.id)
                                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .overlay(alignment: .topLeading) {
                        dismissButtonView(geometryProxy: g)
                    }
                } else {
                    Group {
                        if inputViewModel.mediaPickerMode == .camera || inputViewModel.mediaPickerMode == .cameraSelection {
                            SHCameraPickerView { asseetUrl in
                                let media = Media(source: URLMediaModel(url: asseetUrl))
                                seleсtedMedias = [media]
                                assembleSelectedMedia()
                                convertToMediaItems()
                            }
                        } else {
                            SHAssetPickerView { assets in
                                seleсtedMedias = assets.map{Media(source: AssetMediaModel(asset: $0))}
                                assembleSelectedMedia()
                                convertToMediaItems()
                            }
                        }
                    }
                    .padding(.bottom, UIApplication.shared.safeAreaInsets.bottom + inputViewHeight)
                }
            }
            .overlay(alignment: .bottom) {
                inputView
                    .background(GeometryReader { p in
                        Color.clear
                            .onAppear {
                                inputViewHeight = p.frame(in: .global).height
                                print("\ninputViewHeight: \(inputViewHeight)\n")
                            }
                    })
                    .padding(.bottom, g.safeAreaInsets.bottom)
            }
            .background(mediaPickerTheme.main.pickerBackground.ignoresSafeArea())
            .background(theme.colors.mainBG)
            .ignoresSafeArea(.all)
            .onChange(of: currentFullscreenMedia) {
                assembleSelectedMedia()
            }
            .onChange(of: inputViewModel.showPicker) {
                let showFullscreenPreview = mediaPickerSelectionParameters?.showFullscreenPreview ?? true
                let selectionLimit = mediaPickerSelectionParameters?.selectionLimit ?? 1

                if selectionLimit == 1 && !showFullscreenPreview {
                    assembleSelectedMedia()
                    inputViewModel.send()
                }
            }
            .applyIf(!mediaPickerThemeIsOverridden) {
                $0.mediaPickerTheme(
                    main: .init(
                        pickerText: theme.colors.mainText,
                        pickerBackground: theme.colors.mainBG,
                        fullscreenPhotoBackground: theme.colors.mainBG
                    ),
                    selection: .init(
                        accent: theme.colors.sendButtonBackground
                    )
                )
            }
        }
    }
    func convertToMediaItems() {
        Task {
            var loadedItems: [MediaItemWithURL] = []

            for media in seleсtedMedias {
                if let url = await media.getURL() {
                    loadedItems.append(MediaItemWithURL(media: media, url: url))
                }
            }

            mediaItems = loadedItems
        }
    }
    func dismissButtonView(geometryProxy: GeometryProxy) -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
        }
        .foregroundStyle(.white, theme.colors.messageMyBG)
        .padding(.top, geometryProxy.safeAreaInsets.top)
        .padding(.leading)
    }

    func assembleSelectedMedia() {
        if !seleсtedMedias.isEmpty {
            inputViewModel.attachments.medias = seleсtedMedias
        } else if let media = currentFullscreenMedia {
            inputViewModel.attachments.medias = [media]
        } else {
            inputViewModel.attachments.medias = []
        }
    }

    @ViewBuilder
    var inputView: some View {
        Group {
            if let inputViewBuilder = inputViewBuilder {
                inputViewBuilder(
                    $inputViewModel.text, inputViewModel.attachments, inputViewModel.state,
                    .signature, inputViewModel.inputViewAction()
                ) {
                    globalFocusState.focus = nil
                }
            } else {
                InputView(
                    viewModel: inputViewModel,
                    inputFieldId: UUID(),
                    style: .signature,
                    availableInputs: availableInputs,
                    messageStyler: messageStyler,
                    localization: localization
                )
            }
        }
    }

    var albumSelectionHeaderView: some View {
        ZStack {
            HStack {
                Button {
                    seleсtedMedias = []
                    inputViewModel.showPicker = false
                } label: {
                    Text(localization.cancelButtonText)
                }

                Spacer()
            }

            HStack {
                Text(localization.recentToggleText)
                Image(systemName: "chevron.down")
                    .rotationEffect(Angle(radians: showingAlbums ? .pi : 0))
            }
            .onTapGesture {
                withAnimation {
                    inputViewModel.mediaPickerMode = showingAlbums ? .photos : .albums
                }
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundColor(mediaPickerTheme.main.pickerText)
        .padding(.horizontal)
        .padding(.bottom, 5)
    }

    func cameraSelectionHeaderView(cancelClosure: @escaping ()->()) -> some View {
        HStack {
            Button(action: cancelClosure) {
                theme.images.mediaPicker.cross
                    .imageScale(.large)
            }
            .tint(mediaPickerTheme.main.pickerText)
            .padding(.trailing, 30)

            if let chatTitle = chatTitle {
                theme.images.mediaPicker.chevronRight
                Text(chatTitle)
                    .font(.title3)
                    .foregroundColor(mediaPickerTheme.main.pickerText)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct MediaItemWithURL {
    let media: Media
    let url: URL
}

extension UIApplication {
    var safeAreaInsets: UIEdgeInsets {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets ?? .zero
    }
}
