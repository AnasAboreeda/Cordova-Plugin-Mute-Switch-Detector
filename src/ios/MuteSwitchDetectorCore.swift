import Foundation
import AudioToolbox

final public class MuteSwitchDetectorCore {

    public typealias MuteNotificationCompletion = ((_ mute: Bool) -> Void)

    // MARK: Properties

    /// Shared instance
    public static let shared = MuteSwitchDetectorCore()

    /// Sound ID for mute sound
    private let soundUrl = MuteSwitchDetectorCore.muteSoundUrl

    /// Should notify every second or only when changes?
    /// True will notify every second of the state, false only when it changes
    public var alwaysNotify = true

    /// Notification handler to be triggered when mute status changes
    /// Triggered every second if alwaysNotify=true, otherwise only when it switches state
    public var notify: MuteNotificationCompletion?

    /// Currently playing? used when returning from the background (if went to background and foreground really quickly)
    public private(set) var isPlaying = false

    /// Current mute state
    public private(set) var isMute = false

    /// State of detection - paused when in background
    public var isPaused = false {
        didSet {
            if !self.isPaused && !self.isPlaying {
                self.schedulePlaySound()
            }
        }
    }

    /// How frequently to check (seconds), minimum = 0.5
    public var checkInterval = 1.0 {
        didSet {
            if self.checkInterval < 0.5 {
                print("MUTE: checkInterval cannot be less than 0.5s, setting to 0.5")
                self.checkInterval = 0.5
            }
        }
    }

    /// Silent sound (0.5 sec)
    private var soundId: SystemSoundID = 0

    /// Time difference between start and finish of mute sound
    private var interval: TimeInterval = 0

    // MARK: Resources

    /// Library bundle
    private static var bundle: Bundle {
        guard let path = Bundle(for: MuteSwitchDetectorCore.self).path(forResource: "MuteSwitchDetector", ofType: "bundle"),
            let bundle = Bundle(path: path) else {
                fatalError("MuteSwitchDetectorCore.bundle not found")
        }

        return bundle
    }

    /// MuteSwitchDetectorCore sound url path
    private static var muteSoundUrl: URL {
        guard let muteSoundUrl = MuteSwitchDetectorCore.bundle.url(forResource: "mute", withExtension: "aiff") else {
            fatalError("mute.aiff not found")
        }
        return muteSoundUrl
    }

    // MARK: Init

    /// private init
    private init() {
        self.soundId = 1

        if AudioServicesCreateSystemSoundID(self.soundUrl as CFURL, &self.soundId) == kAudioServicesNoError {
            let weakSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

            AudioServicesAddSystemSoundCompletion(self.soundId, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue, { soundId, weakSelfPointer in
                guard let weakSelfPointer = weakSelfPointer else { return }

                let weakSelfValue = Unmanaged<MuteSwitchDetectorCore>.fromOpaque(weakSelfPointer).takeUnretainedValue()
                weakSelfValue.soundFinishedPlaying()

            }, weakSelf)

            var yes: UInt32 = 1
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound,
                                     UInt32(MemoryLayout.size(ofValue: self.soundId)),
                                     &self.soundId,
                                     UInt32(MemoryLayout.size(ofValue: yes)),
                                     &yes)

            self.schedulePlaySound()
        } else {
            print("Failed to setup sound player")
            self.soundId = 0
        }

        // Notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MuteSwitchDetectorCore.didEnterBackground(_:)),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MuteSwitchDetectorCore.willEnterForeground(_:)),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
    }

    deinit {
        if self.soundId != 0 {
            AudioServicesRemoveSystemSoundCompletion(self.soundId)
            AudioServicesDisposeSystemSoundID(self.soundId)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Notification Handlers

    /// Selector called when app enters background
    @objc private func didEnterBackground(_ sender: Any) {
        self.isPaused = true
    }

    /// Selector called when app will enter foreground
    @objc private func willEnterForeground(_ sender: Any) {
        self.isPaused = false
    }

    // MARK: Methods

    /// Schedueles mute sound to be played in 1 second
    private func schedulePlaySound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + self.checkInterval) {
            self.playSound()
        }
    }

    /// If not paused, playes mute sound
    private func playSound() {
        if !self.isPaused {
            self.interval = Date.timeIntervalSinceReferenceDate
            self.isPlaying = true
            AudioServicesPlaySystemSound(self.soundId)
        }
    }

    /// Called when AudioService finished playing sound
    private func soundFinishedPlaying() {
        self.isPlaying = false

        let elapsed = Date.timeIntervalSinceReferenceDate - self.interval
        let isMute = elapsed < 0.1

        if self.isMute != isMute || self.alwaysNotify {
            self.isMute = isMute
            self.notify?(isMute)
        }
        self.schedulePlaySound()
    }
}
