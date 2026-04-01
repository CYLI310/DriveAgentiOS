import AVFoundation
import Combine

/// Manages spoken speed-trap announcements using AVSpeechSynthesizer.
/// Each language is mapped to an appropriate BCP-47 locale so iOS
/// selects the correct voice (e.g. zh-TW, ja-JP, ar-SA, etc.).
@MainActor
class VoiceAlertManager: ObservableObject {

    // MARK: - Public Properties

    @Published var voiceAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceAlertsEnabled, forKey: "voiceAlertsEnabled") }
    }

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    /// Minimum seconds between two voice announcements for the same trap state.
    private let cooldown: TimeInterval = 20
    private var lastAnnouncedTrapID: String?
    private var lastAnnounceTime: Date?

    // MARK: - Init

    init() {
        self.voiceAlertsEnabled = UserDefaults.standard.object(forKey: "voiceAlertsEnabled") as? Bool ?? true
    }

    // MARK: - Public API

    /// Announce a speed-trap warning.
    /// - Parameters:
    ///   - distanceMeters: Distance to the trap in metres.
    ///   - speedLimit: Localised display string of the limit (e.g. "60 km/h").
    ///   - isSpeeding: Whether the user is actively exceeding the limit.
    ///   - language: Current app language for voice selection & text.
    ///   - trapID: A stable identifier for de-duplication (lat/lon string).
    ///   - useMetric: Whether to read distance in metres/km vs feet/miles.
    func announce(
        distanceMeters: Double,
        speedLimit: String,
        isSpeeding: Bool,
        language: AppLanguage,
        trapID: String,
        useMetric: Bool
    ) {
        guard voiceAlertsEnabled else { return }

        let now = Date()
        // De-duplicate: same trap & inside cooldown window → skip
        if trapID == lastAnnouncedTrapID,
           let last = lastAnnounceTime,
           now.timeIntervalSince(last) < cooldown {
            return
        }

        lastAnnouncedTrapID = trapID
        lastAnnounceTime = now

        let text = buildAnnouncementText(
            distanceMeters: distanceMeters,
            speedLimit: speedLimit,
            isSpeeding: isSpeeding,
            language: language,
            useMetric: useMetric
        )

        speak(text: text, language: language)
    }

    /// Immediately stop any ongoing speech (e.g. when alert clears).
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Reset cooldown so next proximity entry always fires.
    func resetCooldown() {
        lastAnnouncedTrapID = nil
        lastAnnounceTime = nil
    }

    // MARK: - Text Construction

    private func buildAnnouncementText(
        distanceMeters: Double,
        speedLimit: String,
        isSpeeding: Bool,
        language: AppLanguage,
        useMetric: Bool
    ) -> String {
        let distanceStr = formatDistance(distanceMeters, useMetric: useMetric, language: language)
        let limitStr = speedLimit.replacingOccurrences(of: ".0", with: "")

        if isSpeeding {
            return speedingTemplate(language: language, distance: distanceStr, limit: limitStr)
        } else {
            return approachingTemplate(language: language, distance: distanceStr, limit: limitStr)
        }
    }

    // MARK: - Localised Announcement Templates

    /// "Speed camera ahead in X. Limit is Y. Reduce speed."
    private func approachingTemplate(language: AppLanguage, distance: String, limit: String) -> String {
        switch language {
        case .english:
            return "Speed camera ahead in \(distance). Speed limit: \(limit)."
        case .chineseTraditional:
            return "前方 \(distance) 有測速照相，速限 \(limit)。"
        case .chineseSimplified:
            return "前方 \(distance) 有测速照相，限速 \(limit)。"
        case .korean:
            return "전방 \(distance)에 과속 카메라가 있습니다. 제한 속도: \(limit)."
        case .japanese:
            return "前方 \(distance) にスピードカメラがあります。速度制限: \(limit)。"
        case .vietnamese:
            return "Phía trước \(distance) có camera tốc độ. Giới hạn: \(limit)."
        case .thai:
            return "ข้างหน้า \(distance) มีกล้องตรวจจับความเร็ว จำกัดความเร็ว \(limit)"
        case .filipino:
            return "May speed camera sa \(distance) sa harap. Limitasyon: \(limit)."
        case .hindi:
            return "आगे \(distance) पर स्पीड कैमरा है। गति सीमा: \(limit)।"
        case .arabic:
            return "كاميرا سرعة على بُعد \(distance). الحد: \(limit)."
        case .spanish:
            return "Cámara de velocidad en \(distance). Límite: \(limit)."
        case .german:
            return "Blitzer in \(distance). Tempolimit: \(limit)."
        case .french:
            return "Radar dans \(distance). Limitation: \(limit)."
        case .italian:
            return "Autovelox tra \(distance). Limite: \(limit)."
        case .portuguese:
            return "Radar daqui a \(distance). Limite: \(limit)."
        case .russian:
            return "Камера через \(distance). Ограничение: \(limit)."
        }
    }

    /// "You are speeding! Camera in X. Limit is Y. Reduce speed immediately."
    private func speedingTemplate(language: AppLanguage, distance: String, limit: String) -> String {
        switch language {
        case .english:
            return "Warning! You are speeding. Camera in \(distance). Limit: \(limit). Reduce speed immediately."
        case .chineseTraditional:
            return "警告！您正在超速。前方 \(distance) 有測速照相，速限 \(limit)，請立即減速。"
        case .chineseSimplified:
            return "警告！您正在超速。前方 \(distance) 有测速照相，限速 \(limit)，请立即减速。"
        case .korean:
            return "경고! 과속 중입니다. \(distance) 앞에 카메라가 있습니다. 제한: \(limit). 즉시 속도를 줄이세요."
        case .japanese:
            return "警告！速度超過です。\(distance) 先にカメラがあります。制限: \(limit)。すぐに減速してください。"
        case .vietnamese:
            return "Cảnh báo! Bạn đang chạy quá tốc độ. Camera cách \(distance). Giới hạn: \(limit). Giảm tốc ngay."
        case .thai:
            return "คำเตือน! คุณขับเร็วเกิน กล้องอีก \(distance) ข้างหน้า จำกัด \(limit) ลดความเร็วทันที"
        case .filipino:
            return "Babala! Sobra ka sa bilis. Camera sa \(distance). Limitasyon: \(limit). Bawasan ang bilis agad."
        case .hindi:
            return "चेतावनी! आप तेज़ गति से चल रहे हैं। \(distance) पर कैमरा है। सीमा: \(limit)। तुरंत धीमा करें।"
        case .arabic:
            return "تحذير! أنت تتجاوز السرعة. كاميرا بعد \(distance). الحد: \(limit). خفف السرعة فورًا."
        case .spanish:
            return "¡Advertencia! Estás excediendo la velocidad. Cámara en \(distance). Límite: \(limit). Reduce la velocidad."
        case .german:
            return "Warnung! Sie fahren zu schnell. Blitzer in \(distance). Tempolimit: \(limit). Sofort bremsen."
        case .french:
            return "Attention! Vous excédez la vitesse. Radar dans \(distance). Limite: \(limit). Ralentissez immédiatement."
        case .italian:
            return "Attenzione! Stai superando il limite. Autovelox tra \(distance). Limite: \(limit). Rallenta subito."
        case .portuguese:
            return "Atenção! Você está acima do limite. Radar em \(distance). Limite: \(limit). Reduza a velocidade."
        case .russian:
            return "Внимание! Вы превышаете скорость. Камера через \(distance). Ограничение: \(limit). Немедленно снизьте скорость."
        }
    }

    // MARK: - Distance Formatting

    private func formatDistance(_ meters: Double, useMetric: Bool, language: AppLanguage) -> String {
        if useMetric {
            if meters >= 1000 {
                let km = meters / 1000
                let formatted = String(format: "%.1f", km)
                return "\(formatted) \(kmWord(language))"
            } else {
                return "\(Int(meters)) \(meterWord(language))"
            }
        } else {
            let feet = meters * 3.28084
            if feet >= 5280 {
                let miles = feet / 5280
                let formatted = String(format: "%.1f", miles)
                return "\(formatted) \(mileWord(language))"
            } else {
                return "\(Int(feet)) \(feetWord(language))"
            }
        }
    }

    private func meterWord(_ lang: AppLanguage) -> String {
        switch lang {
        case .chineseTraditional, .chineseSimplified: return "公尺"
        case .korean: return "미터"
        case .japanese: return "メートル"
        case .thai: return "เมตร"
        case .hindi: return "मीटर"
        case .arabic: return "متر"
        case .russian: return "м"
        default: return "meters"
        }
    }

    private func kmWord(_ lang: AppLanguage) -> String {
        switch lang {
        case .chineseTraditional, .chineseSimplified: return "公里"
        case .korean: return "킬로미터"
        case .japanese: return "キロ"
        case .thai: return "กิโลเมตร"
        case .hindi: return "किलोमीटर"
        case .arabic: return "كم"
        case .russian: return "км"
        default: return "kilometers"
        }
    }

    private func feetWord(_ lang: AppLanguage) -> String {
        switch lang {
        case .chineseTraditional, .chineseSimplified: return "英尺"
        case .japanese: return "フィート"
        case .korean: return "피트"
        case .arabic: return "قدم"
        case .russian: return "фут"
        default: return "feet"
        }
    }

    private func mileWord(_ lang: AppLanguage) -> String {
        switch lang {
        case .chineseTraditional, .chineseSimplified: return "英里"
        case .japanese: return "マイル"
        case .korean: return "마일"
        case .arabic: return "ميل"
        case .russian: return "мили"
        default: return "miles"
        }
    }

    // MARK: - Speech

    private func speak(text: String, language: AppLanguage) {
        // Stop any in-progress utterance first
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92 // Slightly slower for clear driving comprehension
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Pick the best matching voice for the language
        utterance.voice = preferredVoice(for: language)

        synthesizer.speak(utterance)
    }

    // MARK: - Voice Selection

    /// Returns the best available `AVSpeechSynthesisVoice` for the given language.
    /// Prefers an "enhanced" quality voice when available, falls back gracefully.
    private func preferredVoice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let locale = bcp47Locale(for: language)

        // Try to find an enhanced voice first (Siri voices on-device)
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let candidates = allVoices.filter { $0.language.hasPrefix(locale) }

        if let enhanced = candidates.first(where: {
            if #available(iOS 16.0, *) { return $0.quality == .enhanced || $0.quality == .premium }
            return false
        }) {
            return enhanced
        }

        // Fall back to any available voice matching the locale prefix
        if let any = candidates.first {
            return any
        }

        // Last resort: system default for the locale string
        return AVSpeechSynthesisVoice(language: locale)
    }

    /// Maps each AppLanguage to the BCP-47 language tag used by AVSpeechSynthesisVoice.
    private func bcp47Locale(for language: AppLanguage) -> String {
        switch language {
        case .english:            return "en-US"
        case .chineseTraditional: return "zh-TW"
        case .chineseSimplified:  return "zh-CN"
        case .korean:             return "ko-KR"
        case .japanese:           return "ja-JP"
        case .vietnamese:         return "vi-VN"
        case .thai:               return "th-TH"
        case .filipino:           return "fil-PH"
        case .hindi:              return "hi-IN"
        case .arabic:             return "ar-SA"
        case .spanish:            return "es-ES"
        case .german:             return "de-DE"
        case .french:             return "fr-FR"
        case .italian:            return "it-IT"
        case .portuguese:         return "pt-BR"
        case .russian:            return "ru-RU"
        }
    }
}
