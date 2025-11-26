import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case chineseTraditional = "繁體中文"
    
    var id: String { self.rawValue }
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
        if let saved = savedLanguage, let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .english
        }
    }
    
    // Dictionary of translations
    private let translations: [String: [AppLanguage: String]] = [
        // General
        "Settings": [.english: "Settings", .chineseTraditional: "設定"],
        "Done": [.english: "Done", .chineseTraditional: "完成"],
        "Back": [.english: "Back", .chineseTraditional: "返回"],
        "Next": [.english: "Next", .chineseTraditional: "下一步"],
        "Get Started": [.english: "Get Started", .chineseTraditional: "開始使用"],
        
        // ContentView
        "Searching for location...": [.english: "Searching for location...", .chineseTraditional: "正在搜尋位置..."],
        "Speed Camera Ahead!": [.english: "Speed Camera Ahead!", .chineseTraditional: "前方有測速照相！"],
        "Limit": [.english: "Limit", .chineseTraditional: "速限"],
        "Trip Distance": [.english: "Trip Distance", .chineseTraditional: "行駛距離"],
        "Max Speed": [.english: "Max Speed", .chineseTraditional: "最高速度"],
        "Location Access Denied": [.english: "Location Access Denied", .chineseTraditional: "無法存取位置"],
        "Location Permission Text": [.english: "To provide speed and location data, this app needs access to your location. Please enable it in Settings.", .chineseTraditional: "為了提供速度和位置資訊，本應用程式需要存取您的位置。請在設定中啟用。"],
        "Open Settings": [.english: "Open Settings", .chineseTraditional: "開啟設定"],
        
        // SettingsView
        "Language": [.english: "Language", .chineseTraditional: "語言"],
        "Appearance": [.english: "Appearance", .chineseTraditional: "外觀"],
        "Theme": [.english: "Theme", .chineseTraditional: "主題"],
        "Particle Effects": [.english: "Particle Effects", .chineseTraditional: "粒子特效"],
        "Effect Style": [.english: "Effect Style", .chineseTraditional: "特效樣式"],
        "Units": [.english: "Units", .chineseTraditional: "單位"],
        "Use Metric": [.english: "Use Metric (km/h, km)", .chineseTraditional: "使用公制 (km/h, km)"],
        "Metric Description": [.english: "Speed in km/h, distance in km/m", .chineseTraditional: "速度顯示 km/h，距離顯示 km/m"],
        "Imperial Description": [.english: "Speed in mph, distance in mi/ft", .chineseTraditional: "速度顯示 mph，距離顯示 mi/ft"],
        "Trip": [.english: "Trip", .chineseTraditional: "行程"],
        "Distance": [.english: "Distance", .chineseTraditional: "距離"],
        "Reset Trip": [.english: "Reset Trip", .chineseTraditional: "重置行程"],
        "Speed Camera Alerts": [.english: "Speed Camera Alerts", .chineseTraditional: "測速照相警示"],
        "Infinite Proximity": [.english: "Infinite Proximity", .chineseTraditional: "無限偵測距離"],
        "Infinite Proximity On": [.english: "Will always show the absolute closest speed camera, regardless of distance", .chineseTraditional: "無論距離多遠，總是顯示最近的測速照相"],
        "Infinite Proximity Off": [.english: "Only shows speed cameras within 2km", .chineseTraditional: "僅顯示 2 公里內的測速照相"],
        "Alert Distance": [.english: "Alert Distance", .chineseTraditional: "警示距離"],
        "Alert Distance Description": [.english: "You'll be alerted when within this distance of a speed camera", .chineseTraditional: "當進入此距離範圍內時將發出警示"],
        "Other Settings": [.english: "Other Settings", .chineseTraditional: "其他設定"],
        "Show Tutorial": [.english: "Show Tutorial", .chineseTraditional: "顯示教學"],
        
        // Particle Styles
        "No particle effects will be shown": [.english: "No particle effects will be shown", .chineseTraditional: "不顯示粒子特效"],
        "Particles orbit around the speed display": [.english: "Particles orbit around the speed display", .chineseTraditional: "粒子環繞速度顯示"],
        "Particles pulse in and out rhythmically": [.english: "Particles pulse in and out rhythmically", .chineseTraditional: "粒子有節奏地脈動"],
        "Particles move in a dynamic spiral pattern": [.english: "Particles move in a dynamic spiral pattern", .chineseTraditional: "粒子以動態螺旋方式移動"],
        
        // SpeedTrapListView
        "Nearest Speed Cameras": [.english: "Nearest Speed Cameras", .chineseTraditional: "附近測速照相"],
        
        // Onboarding
        "Track Your Speed": [.english: "Track Your Speed", .chineseTraditional: "追蹤速度"],
        "Track Speed Desc": [.english: "See your current speed in real-time with dynamic particle effects that change color based on acceleration", .chineseTraditional: "即時查看當前速度，搭配隨加速度變色的動態粒子特效"],
        "View Your Route": [.english: "View Your Route", .chineseTraditional: "查看路線"],
        "View Route Desc": [.english: "Tap the map button to see your location on the map. Use the X button to exit map view", .chineseTraditional: "點擊地圖按鈕查看您的位置。使用 X 按鈕退出地圖視圖"],
        "Speed Cameras": [.english: "Speed Cameras", .chineseTraditional: "測速照相"],
        "Speed Cameras Desc": [.english: "Tap the camera button to see a list of the nearest speed cameras and their distances", .chineseTraditional: "點擊相機按鈕查看最近的測速照相列表及其距離"],
        "Customize Settings": [.english: "Customize Settings", .chineseTraditional: "自訂設定"],
        "Customize Settings Desc": [.english: "Access settings to switch between metric/imperial units, change theme, view trip stats, and reset your trip", .chineseTraditional: "進入設定切換公制/英制單位、更改主題、查看行程統計和重置行程"],
        "Trip Information": [.english: "Trip Information", .chineseTraditional: "行程資訊"],
        "Trip Info Desc": [.english: "When stopped, you'll see your current street, trip distance, max speed, and battery level", .chineseTraditional: "停止時，您將看到當前街道、行程距離、最高速度和電池電量"]
    ]
    
    func localize(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
}
