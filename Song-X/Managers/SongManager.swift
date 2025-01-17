//
//  SongManager.swift
//  Song-X
//
//  Created by Türker Kızılcık on 21.09.2024.
//

import AVFoundation
import SwiftUI

class SongManager: ObservableObject {
    static let shared: SongManager = .init()

    @Published var filePickerClicked = false

    let fileManager = FileManager.default

    var reverbValue: Float = 0.0
    var rateValue: Float = 1.0
    var pitchValue: Float = 0.0
    var frequencyValue: Float = 1500
    var isFilterEnabled: Bool = false
    var reverbType: AVAudioUnitReverbPreset = .mediumRoom

    var isPlaying = false {
        willSet {
            withAnimation {
                objectWillChange.send()
            }
        }
    }

    var playerProgress: Double = 0 {
        willSet {
            objectWillChange.send()
        }
    }

    var playerTime: PlayerTime = .zero {
        willSet {
            objectWillChange.send()
        }
    }

    var needsFileScheduled = true

    let songEngine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let eq = AVAudioUnitEQ(numberOfBands: 1)
    let reverb = AVAudioUnitReverb()
    let pitchEffect = AVAudioUnitTimePitch()

    var pickedURL: URL?
    var pickedSongName: String = "Unknown Song"
    var pickedAudioFile: AVAudioFile?

    var audioSampleRate: Double = 0
    var audioLengthSeconds: Double = 0
    var audioLengthSamples: AVAudioFramePosition = 0

    var displayLink: CADisplayLink?

    var seekFrame: AVAudioFramePosition = 0
    var currentPosition: AVAudioFramePosition = 0
    var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }

        return playerTime.sampleTime
    }
}

extension SongManager {

    func setup() {
        configureAudioSession()
        createSongXFolder()
        setupDisplayLink()
    }

    func setupAudio() {
        guard
            let url = SongManager.shared.pickedURL,
            url.startAccessingSecurityScopedResource(),
            let audioFile = SongManager.shared.loadAudioFile(from: url)
        else { return }

        url.stopAccessingSecurityScopedResource()

        let format = audioFile.processingFormat
        audioLengthSamples = audioFile.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate

        pickedAudioFile = audioFile

        configureEngine(with: format)
    }

    func reset() {
        isPlaying = false
        playerProgress = 0
        playerTime = .zero
        needsFileScheduled = true
        seekFrame = 0
        currentPosition = 0

        reverbValue = 0.0
        rateValue = 1.0
        pitchValue = 0.0

        songEngine.stop()
        player.stop()
    }

    func configureEngine(with format: AVAudioFormat) {
        songEngine.attach(eq)
        songEngine.attach(player)
        songEngine.attach(reverb)
        songEngine.attach(pitchEffect)

        songEngine.connect(player, to: reverb, format: format)
        songEngine.connect(reverb, to: eq, format: format)
        songEngine.connect(eq, to: pitchEffect, format: format)
        songEngine.connect(pitchEffect, to: songEngine.mainMixerNode, format: format)

        songEngine.prepare()

        do {
            try songEngine.start()
            scheduleAudioFile()
        } catch {
            print("Error starting the player: \(error.localizedDescription)")
        }
    }

    func scheduleAudioFile() {
        guard
            let file = pickedAudioFile,
            needsFileScheduled
        else {
            print("A file hasn't been picked.")
            return
        }

        needsFileScheduled = false
        seekFrame = 0

        player.scheduleFile(file, at: nil) {
            self.needsFileScheduled = true
        }
    }

    func playOrPause() {
        guard pickedAudioFile != nil else { return }

        isPlaying.toggle()

        switch player.isPlaying {
        case true:
            displayLink?.isPaused = true
            player.pause()

        case false:
            if needsFileScheduled {
                scheduleAudioFile()
            }
            displayLink?.isPaused = false
            player.play()
        }
    }

    func skip(forwards: Bool) {
        let timeToSeek = forwards ? 5.0 : -5.0
        seek(to: timeToSeek)
    }

    func changeAudio() {
        guard let band = eq.bands.first else { return }

        band.filterType = .lowPass
        band.frequency = frequencyValue
        band.bypass = !isFilterEnabled // should be set to true or false on user's request. (false means it will filter it)

        reverb.loadFactoryPreset(reverbType)
        reverb.wetDryMix = reverbValue
        pitchEffect.rate = rateValue
        pitchEffect.pitch = pitchValue
    }

    func loadAudioFile(from url: URL) -> AVAudioFile? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            print("Error loading audio file")
            return nil
        }
        return audioFile
    }

    func saveAudio() {
        guard
            let url = SongManager.shared.pickedURL,
            url.startAccessingSecurityScopedResource(),
            let audioFile = SongManager.shared.loadAudioFile(from: url)
        else { return }

        let format = audioFile.processingFormat

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        let reverb = AVAudioUnitReverb()
        let pitchEffect = AVAudioUnitTimePitch()

        engine.attach(player)
        engine.attach(reverb)
        engine.attach(pitchEffect)
        engine.attach(eq)

        guard let band = eq.bands.first else { return }

        band.filterType = .lowPass
        band.frequency = frequencyValue
        band.bypass = !isFilterEnabled

        reverb.loadFactoryPreset(reverbType)
        reverb.wetDryMix = reverbValue
        pitchEffect.pitch = pitchValue
        pitchEffect.rate = rateValue

        engine.connect(player, to: reverb, format: format)
        engine.connect(reverb, to: eq, format: format)
        engine.connect(eq, to: pitchEffect, format: format)
        engine.connect(pitchEffect, to: engine.mainMixerNode, format: format)

        player.scheduleFile(audioFile, at: nil)

        do {
            let maxFrames: AVAudioFrameCount = 4096
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxFrames)
        } catch {
            fatalError("Enabling manual rendering mode failed: \(error).")
        }

        do {
            try engine.start()
            player.play()
        } catch {
            fatalError("Unable to start audio engine: \(error).")
        }

        let buffer: AVAudioPCMBuffer = .init(
            pcmFormat: engine.manualRenderingFormat,
            frameCapacity: engine.manualRenderingMaximumFrameCount
        )!

        let outputFile: AVAudioFile
        do {
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outputURL = documentsURL.appendingPathComponent("Edited Songs/\(SongManager.shared.pickedSongName).m4a")

            let outputFormat = engine.manualRenderingFormat
            outputFile = try AVAudioFile(forWriting: outputURL, settings: outputFormat.settings)
        } catch {
            fatalError("Unable to open output audio file: \(error).")
        }

        // Calculate the new length based on the rate
        let newLength = AVAudioFramePosition(Double(audioFile.length) / Double(rateValue))

        while engine.manualRenderingSampleTime < newLength {
            do {
                let frameCount = newLength - engine.manualRenderingSampleTime
                let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)

                let status = try engine.renderOffline(framesToRender, to: buffer)

                switch status {
                case .success:
                    try outputFile.write(from: buffer)

                case .insufficientDataFromInputNode:
                    break

                case .cannotDoInCurrentContext:
                    break

                case .error:
                    fatalError("The manual rendering failed.")
                @unknown default:
                    fatalError("Unknown error occurred during rendering.")
                }
            } catch {
                fatalError("The manual rendering failed: \(error).")
            }
        }

        player.stop()
        engine.stop()

        print("AVAudioEngine offline rendering finished.")

        // SongManager'ı sıfırla ve yeniden yapılandır
        self.reset()
        self.setupAudio()
    }

    func compressAudio(completion: @escaping (Error?) -> Void) {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let inputURL = documentsURL.appendingPathComponent("Edited Songs/\(SongManager.shared.pickedSongName).m4a")

        let asset = AVAsset(url: inputURL)

        let outputURL = documentsURL.appendingPathComponent(
            "Edited Songs/SongX_\(SongManager.shared.pickedSongName).m4a"
        )

        deleteFileIfNeeded(at: outputURL)

        guard
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        else {
            completion(
                NSError(
                    domain: "com.songx.error",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"]
                )
            )
            return
        }

        exportSession.outputFileType = .m4a
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true

        let audioMix = AVMutableAudioMix()
        // TODO: will be fixed
        guard let track = asset.tracks.first else {
            print("Error! InputURL doesn't exist.")
            return
        }
        let audioParameters = AVMutableAudioMixInputParameters(track: track)
        audioParameters.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
        audioMix.inputParameters = [audioParameters]
        exportSession.audioMix = audioMix

        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                completion(error)
            } else {
                self.deleteFileIfNeeded(at: inputURL)
            }
        }
    }

    func setAudioProperties(reverb: Float, rate: Float, pitch: Float, frequency: Float) {
        reverbValue = reverb
        rateValue = rate
        pitchValue = pitch
        frequencyValue = frequency
        changeAudio()
    }

    @objc private func updateDisplay() {
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)

        if currentPosition >= audioLengthSamples {
            player.stop()

            seekFrame = 0
            currentPosition = 0

            isPlaying = false
            displayLink?.isPaused = true

        }

        playerProgress = Double(currentPosition) / Double(audioLengthSamples)

        let time = Double(currentPosition) / audioSampleRate
        playerTime = PlayerTime(
            elapsedTime: time,
            remainingTime: audioLengthSeconds - time)
    }

    func seek(to time: Double) {
        guard let audioFile = pickedAudioFile else {
            return
        }

        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offset
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame

        let wasPlaying = player.isPlaying
        player.stop()

        if currentPosition < audioLengthSamples {
            needsFileScheduled = false
            updateDisplay()

            let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)
            player.scheduleSegment(
                audioFile,
                startingFrame: seekFrame,
                frameCount: frameCount,
                at: nil
            ) {
                self.needsFileScheduled = true
            }

            if wasPlaying {
                player.play()
            }
        }
    }

    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }

    func createSongXFolder() {
        guard
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }

        let myFolderURL = documentsDirectory.appendingPathComponent("Edited Songs")

        guard !fileManager.fileExists(atPath: myFolderURL.path) else {
            print("File already exists: \(myFolderURL.path)")
            return
        }

        do {
            try fileManager.createDirectory(at: myFolderURL, withIntermediateDirectories: true, attributes: nil)
            print("File created at: \(myFolderURL.path)")
        } catch {
            print("File creation error: \(error.localizedDescription)")
        }
    }

    func deleteFileIfNeeded(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: url)
            print("Folder deleted at url: \(url)")
        } catch {
            print("Folder couldn't be deleted. Error: \(error.localizedDescription)")
        }
    }

    func setupDisplayLink() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateDisplay))
        displayLink?.add(to: .current, forMode: .default)
        displayLink?.isPaused = true
    }

    func restoreAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session active: \(error)")
        }
    }
}
