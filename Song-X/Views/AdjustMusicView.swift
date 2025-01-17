//
//  AdjustMusicView.swift
//  Song-X
//
//  Created by Türker Kızılcık on 12.10.2024.
//

import SwiftUI
import Drops
import AVFAudio
import TPackage

struct AdjustMusicView: View {
    @StateObject private var songManager = SongManager.shared
    @State private var selectedEffect: String?

    @State private var shareURL: URL?

    @State private var rate: Double = 1.0
    @State private var reverb: Double = 0.0
    @State private var pitch: Double = 0.0
    @State private var frequency: Double = 1500.0
    @State private var selectedReverbPreset: AVAudioUnitReverbPreset = .mediumRoom
    @State private var isURLSharable: Bool = false

    @State private var isDragging = false
    @State private var dragStartValue: Double = 0
    @State private var dragOffset: Double = 0

    @EnvironmentObject var premiumManager: TKPremiumManager

    let effects: [Effect] = [
        Effect(name: "Nightcore", color: .red, isPremium: false),
        Effect(name: "Slowed & Reverbed", color: .purple, isPremium: true),
        Effect(name: "Sped Up", color: .blue, isPremium: true),
        Effect(name: "Bathroom Effect", color: .pink, isPremium: false)
    ]

    let drop = Drop(title: "Saved!",
                    icon: UIImage(systemName: "square.and.arrow.down")?
        .withTintColor(.purple, renderingMode: .alwaysOriginal),
                    position: .bottom)


    @State private var scale: CGFloat = 1.0

    var currentProgress: Double {
        if isDragging {
            return min(max(dragStartValue + dragOffset, 0), 1)
        } else {
            return songManager.playerProgress
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: UIScreen.main.bounds.width * 0.75, height: UIScreen.main.bounds.width * 0.75)

                        Image(systemName: "waveform.path")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.5, height: UIScreen.main.bounds.width * 0.5)
                            .foregroundStyle(.gray)
                            .scaleEffect(songManager.isPlaying ? 0.8 : 1.0)
                            .animation(songManager.isPlaying ?
                                .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                    .easeInOut(duration: 0.3),
                                       value: songManager.isPlaying)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.75, height: UIScreen.main.bounds.width * 0.75)
                    .padding(16)

                    HStack {
                        VStack {
                            Text(songManager.pickedSongName)
                                .font(.system(size: 20)).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Unknown Artist")
                                .foregroundStyle(.gray)
                                .font(.system(size: 20))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            ProgressView(value: currentProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .secondary))
                            
                            // Sürüklenebilir alan
                            Color.clear
                                .frame(width: 20, height: 20)
                                .contentShape(Rectangle())
                                .position(x: currentProgress * geometry.size.width, y: geometry.size.height / 2)
                                .gesture(
                                    DragGesture(minimumDistance: 2)
                                        .onChanged { value in
                                            if !isDragging {
                                                isDragging = true
                                                dragStartValue = songManager.playerProgress
                                                dragOffset = 0
                                            }
                                            let delta = value.translation.width / geometry.size.width
                                            dragOffset = delta
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                            let seekValue = dragOffset * songManager.audioLengthSeconds
                                            songManager.seek(to: seekValue)
                                            dragOffset = 0
                                        }
                                )
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                    .padding(.vertical, 4)

                    HStack {
                        Text(songManager.playerTime.elapsedText)
                            .font(.system(.caption, design: .default, weight: .heavy))
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("-" + songManager.playerTime.remainingText)
                            .font(.system(.caption, design: .default, weight: .heavy))
                            .foregroundStyle(.gray)

                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                    HStack {
                        Spacer()
                        Button(action: {
                            songManager.skip(forwards: false)
                        }) {
                            Image(systemName: "gobackward.5")
                                .font(.system(size: 32, weight: .semibold))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Button(action: {
                            songManager.playOrPause()
                        }) {
                            Image(systemName: songManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Button(action: {
                            songManager.skip(forwards: true)
                        }) {
                            Image(systemName: "goforward.5")
                                .font(.system(size: 32, weight: .semibold))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 32)

                    DisclosureGroup {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),  // Sütunlar arası boşluk 16
                            GridItem(.flexible(), spacing: 16)   // Sütunlar arası boşluk 16
                        ], spacing: 16) {  // Satırlar arası boşluk 8
                            ForEach(effects) { effect in
                                Button(action: {
                                    if !effect.isPremium || premiumManager.isPremium {
                                        selectEffect(effect.name)
                                    }
                                }) {
                                    ZStack {
                                        Rectangle()
                                            .fill(effect.color.gradient)
                                            .aspectRatio(1.3, contentMode: .fit)
                                            .cornerRadius(8)
                                            .opacity(effect.isPremium && !premiumManager.isPremium ? 0.5 : 1.0)

                                        if selectedEffect == effect.name {
                                            RadialGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 120
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }

                                        // Center lock if premium
                                        if effect.isPremium && !premiumManager.isPremium {
                                            Image(systemName: "lock.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }

                                        // Text always at bottom
                                        VStack {
                                            Spacer()
                                            Text(effect.name)
                                                .font(.system(size: 14, design: .rounded))
                                                .fontWeight(.bold)
                                                .padding(12)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .disabled(effect.isPremium && !premiumManager.isPremium)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Label {
                            Text("Effects")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding(.vertical, 8)
                                .padding(.leading, 4)
                        } icon: {
                            Image(systemName: "sparkles")
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                        .foregroundStyle(.gray)
                    }
                    .accentColor(.gray)
                    .padding(.horizontal)

                    DisclosureGroup {
                        VStack(spacing: 20) {
                            SliderView(value: $rate,
                                       range: 0.0...2.0,
                                       title: "Rate",
                                       infoText: "Rate allows you to change the **speed** of the song. Slower speeds create a relaxed vibe, while faster speeds feel more energetic. Recommended values typically range from **0.80** to **1.20**.",
                                       level: "BASIC",
                                       levelColor: .blue,
                                       imageName: "timer",
                                       valueString: String(format: "%.2f", rate)) { newValue in
                                songManager.rateValue = Float(newValue)
                                songManager.changeAudio()
                            }
                            .onChange(of: rate) { newValue in
                                songManager.rateValue = Float(newValue)
                                songManager.changeAudio()
                            }

                            SliderView(value: $reverb,
                                       range: 0...100,
                                       title: "Reverb",
                                       infoText: "Reverb allows you to add an **echo** effect to the song. Subtle reverb creates a softer sound, while strong reverb makes it feel fuller and richer. Recommended values typically range from **10** to **50**.",
                                       level: "BASIC",
                                       levelColor: .blue,
                                       imageName: "wave.3.forward",
                                       valueString: String(format: "%.0f", reverb)) { newValue in
                                songManager.reverbValue = Float(newValue)
                                songManager.changeAudio()
                            }
                            .onChange(of: reverb) { newValue in
                                songManager.reverbValue = Float(newValue)
                                songManager.changeAudio()
                            }

                            SliderView(value: $pitch,
                                       range: -1200...1200,
                                       title: "Pitch",
                                       infoText: "Pitch allows you to change the **tone** of the song. Lower pitches create a deeper sound, while higher pitches feel sharper. Recommended values typically range from **-400** to **400**.",
                                       level: "BASIC",
                                       levelColor: .blue,
                                       imageName: "tuningfork",
                                       valueString: String(format: "%.0f", pitch)) { newValue in
                                songManager.pitchValue = Float(newValue)
                                songManager.changeAudio()
                            }
                            .onChange(of: pitch) { newValue in
                                songManager.pitchValue = Float(newValue)
                                songManager.changeAudio()
                            }

                            SliderView(value: $frequency,
                                       range: 0...6000,
                                       title: "Frequency",
                                       infoText: "Frequency allows you to adjust the **sounds** in the song, making it feel like the music is coming from another room. Lower frequencies give a muffled sound, while higher frequencies can make it feel clearer.",
                                       level: "MEDIUM",
                                       levelColor: .orange,
                                       imageName: "waveform",
                                       valueString: String(format: "%.0f", frequency)) { newValue in
                                songManager.frequencyValue = Float(newValue)
                                songManager.changeAudio()
                            }
                            .onChange(of: frequency) { newValue in
                                songManager.frequencyValue = Float(newValue)
                                songManager.changeAudio()
                            }

                            HStack {
                                Toggle(isOn: $songManager.isFilterEnabled) {
                                    Label {
                                        Text("Enable Filtering")
                                            .font(.system(size: 16, weight: .semibold, design: .default))
                                    } icon: {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .onChange(of: songManager.isFilterEnabled) { newValue in
                                    songManager.changeAudio()
                                }
                                .padding(.trailing, 4)
                            }

                            HStack {
                                Label {
                                    Text("Reverb Type")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                } icon: {
                                    Image(systemName: "wave.3.forward")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()
                                Picker(selection: $selectedReverbPreset, label: EmptyView()) {
                                    ForEach(AVAudioUnitReverbPreset.allCases, id: \.self) { preset in
                                        Text(preset.description).tag(preset)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .onChange(of: selectedReverbPreset) { newValue in
                                songManager.reverbType = newValue
                                songManager.changeAudio()
                            }
                        }
                        .padding(.vertical)
                    } label: {
                        Label {
                            Text("Customizations")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding(.vertical, 8)
                                .padding(.leading, 4)
                        } icon: {
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                    }
                    .accentColor(.gray)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Add refresh button
                        Button {
                            // Add haptic feedback
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            
                            withAnimation {
                                resetAllValues()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(.purple)
                        }
                        
                        // Existing menu
                        Menu {
                            Button(action: {
                                songManager.saveAudio()
                                songManager.compressAudio() { error in
                                    print(error.debugDescription)
                                }
                                Drops.show(drop)
                                isURLSharable = true
                            }) {
                                Label {
                                    Text("Save")
                                } icon: {
                                    Image(systemName: "square.and.arrow.down")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.purple)
                                }
                            }

                            ShareLink(item: getUrl()) {
                                Label("Share", systemImage:"square.and.arrow.up")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.purple)
                            }
                            .onTapGesture {
                                songManager.reset()
                                songManager.setupAudio()
                            }
                            .disabled(!isURLSharable)
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
            .onAppear(perform: {
                isShareLinkEnabled()
            })
            .onChange(of: songManager.rateValue) { newValue in
                rate = Double(newValue)
            }
            .onChange(of: songManager.reverbValue) { newValue in
                reverb = Double(newValue)
            }
            .onChange(of: songManager.pitchValue) { newValue in
                pitch = Double(newValue)
            }
            .onDisappear {
                cleanUp()
                songManager.changeAudio()
            }
        }
    }

    func proceedActionHandler() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Edited Songs")
        if let filesAppURL = URL(string: "shareddocuments://\(documentsUrl.path)") {
            UIApplication.shared.open(filesAppURL, options: [:], completionHandler: nil)
        }
    }

    func selectEffect(_ effectName: String) {
        // If the same effect is selected again, reset everything
        if selectedEffect == effectName {
            selectedEffect = nil
            resetAllValues()
            songManager.changeAudio()
            return
        }
        
        selectedEffect = effectName
        switch effectName {
        case "Nightcore":
            SongManager.shared.setAudioProperties(reverb: 0, rate: 1.15, pitch: 300, frequency: 5500)
            SongManager.shared.isFilterEnabled = true
        case "Slowed & Reverbed":
            SongManager.shared.setAudioProperties(reverb: 15, rate: 0.85, pitch: -200, frequency: 5500)
            SongManager.shared.isFilterEnabled = true
        case "Sped Up":
            SongManager.shared.setAudioProperties(reverb: 15, rate: 1.15, pitch: 200, frequency: 5500)
            SongManager.shared.isFilterEnabled = true
        case "Bathroom Effect":
            SongManager.shared.setAudioProperties(reverb: 0, rate: 1, pitch: 0, frequency: 750)
            SongManager.shared.isFilterEnabled = true
        default:
            break
        }

        rate = Double(SongManager.shared.rateValue)
        reverb = Double(SongManager.shared.reverbValue)
        pitch = Double(SongManager.shared.pitchValue)
        frequency = Double(SongManager.shared.frequencyValue)
    }

    func getUrl() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let inputURL = documentsURL.appendingPathComponent(
            "Edited Songs/SongX_\(SongManager.shared.pickedSongName).m4a"
        )

        return inputURL
    }

    func updateShareURL() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        shareURL = documentsURL.appendingPathComponent(
            "Edited Songs/SongX_\(SongManager.shared.pickedSongName).m4a"
        )
    }

    func isShareLinkEnabled() {
        let fileManager = FileManager.default
        let url = getUrl()
        isURLSharable = fileManager.fileExists(atPath: url.path)
    }

    func cleanUp() {
        songManager.reset()

        selectedEffect = nil
        songManager.rateValue = 1.0
        songManager.reverbValue = 0.0
        songManager.pitchValue = 0.0

        rate = 1.0
        reverb = 0.0
        pitch = 0.0
    }

    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func resetAllValues() {
        pitch = 0
        rate = 1.0
        reverb = 0.0
        frequency = 1500.0
        selectedReverbPreset = .mediumRoom
        songManager.isFilterEnabled = false
        selectedEffect = nil

    }
}

struct InfoButton: View {
    let text: LocalizedStringKey
    @State private var showingInfo = false

    var body: some View {
        Button(action: {
            showingInfo = true
        }) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.gray)
        }
        .popover(isPresented: $showingInfo, arrowEdge: .bottom) {
            Text(text)
                .frame(width: 300, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    AdjustMusicView()
}


















