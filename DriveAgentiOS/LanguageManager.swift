import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case chineseTraditional = "繁體中文"
    case chineseSimplified = "简体中文"
    case korean = "한국어"
    case japanese = "日本語"
    case vietnamese = "Tiếng Việt"
    case thai = "ไทย"
    case filipino = " Filipino"
    case hindi = "हिन्दी"
    case arabic = "العربية"
    case spanish = "Español"
    case german = "Deutsch"
    case french = "Français"
    case italian = "Italiano"
    case portuguese = "Português"
    case russian = "Русский"
    
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
            self.currentLanguage = .chineseTraditional
        }
    }
    
    // Dictionary of translations
    private let translations: [String: [AppLanguage: String]] = [
        // General
        "Settings": [
            .english: "Settings", .chineseTraditional: "設定", .chineseSimplified: "设置",
            .korean: "설정", .japanese: "設定", .vietnamese: "Cài đặt", .thai: "การตั้งค่า",
            .filipino: "Mga Setting", .hindi: "सेटिंग्स", .arabic: "الإعدادات", .spanish: "Configuración",
            .german: "Einstellungen", .french: "Paramètres", .italian: "Impostazioni", .portuguese: "Configurações", .russian: "Настройки"
        ],
        "Done": [
            .english: "Done", .chineseTraditional: "完成", .chineseSimplified: "完成",
            .korean: "완료", .japanese: "完了", .vietnamese: "Xong", .thai: "เสร็จสิ้น",
            .filipino: "Tapos na", .hindi: "हो गया", .arabic: "تم", .spanish: "Listo",
            .german: "Fertig", .french: "Terminé", .italian: "Fatto", .portuguese: "Concluído", .russian: "Готово"
        ],
        "Back": [
            .english: "Back", .chineseTraditional: "返回", .chineseSimplified: "返回",
            .korean: "뒤로", .japanese: "戻る", .vietnamese: "Quay lại", .thai: "กลับ",
            .filipino: "Bumalik", .hindi: "वापस", .arabic: "رجوع", .spanish: "Atrás",
            .german: "Zurück", .french: "Retour", .italian: "Indietro", .portuguese: "Voltar", .russian: "Назад"
        ],
        "Next": [
            .english: "Next", .chineseTraditional: "下一步", .chineseSimplified: "下一步",
            .korean: "다음", .japanese: "次へ", .vietnamese: "Tiếp theo", .thai: "ถัดไป",
            .filipino: "Susunod", .hindi: "अगला", .arabic: "التالي", .spanish: "Siguiente",
            .german: "Weiter", .french: "Suivant", .italian: "Avanti", .portuguese: "Próximo", .russian: "Далее"
        ],
        "Get Started": [
            .english: "Get Started", .chineseTraditional: "開始使用", .chineseSimplified: "开始使用",
            .korean: "시작하기", .japanese: "始める", .vietnamese: "Bắt đầu", .thai: "เริ่มต้นใช้งาน",
            .filipino: "Magsimula", .hindi: "شروع करें", .arabic: "البدء", .spanish: "Comenzar",
            .german: "Loslegen", .french: "Commencer", .italian: "Inizia", .portuguese: "Começar", .russian: "Начать"
        ],
        
        // ContentView
        "Searching for location...": [
            .english: "Searching for location...", .chineseTraditional: "正在搜尋位置...", .chineseSimplified: "正在搜索位置...",
            .korean: "위치 검색 중...", .japanese: "位置情報を検索中...", .vietnamese: "Đang tìm vị trí...", .thai: "กำลังค้นหาตำแหน่ง...",
            .filipino: "Naghahanap ng lokasyon...", .hindi: "स्थान खोजा जा रहा है...", .arabic: "جاري البحث عن الموقع...", .spanish: "Buscando ubicación...",
            .german: "Suche nach Standort...", .french: "Recherche de l'emplacement...", .italian: "Ricerca posizione...", .portuguese: "Procurando localização...", .russian: "Поиск местоположения..."
        ],
        "Speed Camera Ahead!": [
            .english: "Speed Camera Ahead!", .chineseTraditional: "前方有測速照相！", .chineseSimplified: "前方有测速照相！",
            .korean: "전방에 과속 단속 카메라!", .japanese: "前方にスピードカメラ！", .vietnamese: "Có camera bắn tốc độ phía trước!", .thai: "ข้างหน้ามีกล้องตรวจจับความเร็ว!",
            .filipino: "May Speed Camera sa Harap!", .hindi: "आगे स्पीड कैमरा है!", .arabic: "كاميرا سرعة أمامك!", .spanish: "¡Cámara de velocidad adelante!",
            .german: "Blitzer voraus!", .french: "Radar automatique devant !", .italian: "Autovelox in arrivo!", .portuguese: "Radar de velocidade à frente!", .russian: "Впереди камера контроля скорости!"
        ],
        "Limit": [
            .english: "Limit", .chineseTraditional: "速限", .chineseSimplified: "限速",
            .korean: "제한", .japanese: "制限", .vietnamese: "Giới hạn", .thai: "จำกัด",
            .filipino: "Limitasyon", .hindi: "सीमा", .arabic: "الحد", .spanish: "Límite",
            .german: "Limit", .french: "Limite", .italian: "Limite", .portuguese: "Limite", .russian: "Лимит"
        ],
        "Trip Distance": [
            .english: "Trip Distance", .chineseTraditional: "行駛距離", .chineseSimplified: "行驶距离",
            .korean: "주행 거리", .japanese: "走行距離", .vietnamese: "Quãng đường", .thai: "ระยะทางทริป",
            .filipino: "Distansya ng Biyahe", .hindi: "यात्रा की दूरी", .arabic: "مسافة الرحلة", .spanish: "Distancia del viaje",
            .german: "Reisedistanz", .french: "Distance du trajet", .italian: "Distanza viaggio", .portuguese: "Distância da viagem", .russian: "Расстояние поездки"
        ],
        "Max Speed": [
            .english: "Max Speed", .chineseTraditional: "最高速度", .chineseSimplified: "最高速度",
            .korean: "최고 속도", .japanese: "最高速度", .vietnamese: "Tốc độ tối đa", .thai: "ความเร็วสูงสุด",
            .filipino: "Pinakamabilis", .hindi: "अधिकतम गति", .arabic: "السرعة القصوى", .spanish: "Velocidad máx.",
            .german: "Max. Geschwindigkeit", .french: "Vitesse max", .italian: "Velocità max", .portuguese: "Velocidade máx.", .russian: "Макс. скорость"
        ],
        "Location Access Denied": [
            .english: "Location Access Denied", .chineseTraditional: "無法存取位置", .chineseSimplified: "无法存取位置",
            .korean: "위치 액세스 거부됨", .japanese: "位置情報へのアクセスが拒否されました", .vietnamese: "Truy cập vị trí bị từ chối", .thai: "การเข้าถึงตำแหน่งถูกปฏิเสธ",
            .filipino: "Tinanggihan ang Access sa Lokasyon", .hindi: "स्थान का उपयोग अस्वीकृत", .arabic: "تم رفض الوصول إلى الموقع", .spanish: "Acceso a ubicación denegado",
            .german: "Standortzugriff verweigert", .french: "Accès à la localisation refusé", .italian: "Accesso alla posizione negato", .portuguese: "Acesso à localização negado", .russian: "Доступ к местоположению запрещен"
        ],
        "Location Permission Text": [
            .english: "To provide speed and location data, this app needs access to your location. Please enable it in Settings.",
            .chineseTraditional: "為了提供速度和位置資訊，本應用程式需要存取您的位置。請在設定中開啟。",
            .chineseSimplified: "为了提供速度和位置数据，本应用需要存取您的位置。请在设置中启用。",
            .korean: "속도 및 위치 데이터를 제공하려면 이 앱에서 위치에 액세스해야 합니다. 설정에서 활성화해주세요.",
            .japanese: "速度と位置情報を提供するには、このアプリが位置情報にアクセスする必要があります。設定で有効にしてください。",
            .vietnamese: "Để cung cấp dữ liệu tốc độ và vị trí, ứng dụng này cần truy cập vị trí của bạn. Vui lòng bật trong Cài đặt.",
            .thai: "เพื่อให้ข้อมูลความเร็วและตำแหน่ง แอปนี้จำเป็นต้องเข้าถึงตำแหน่งของคุณ โปรดเปิดใช้งานในการตั้งค่า",
            .filipino: "Upang magbigay ng data ng bilis at lokasyon, kailangan ng app na ito ng access sa iyong lokasyon. Mangyaring paganahin ito sa Mga Setting.",
            .hindi: "गति और स्थान डेटा प्रदान करने के लिए, इस ऐप को आपके स्थान तक पहुंच की आवश्यकता है। कृपया इसे सेटिंग्स में सक्षम करें।",
            .arabic: "لتوفير بيانات السرعة والموقع، يحتاج هذا التطبيق إلى الوصول إلى موقعك. يرجى تمكينه في الإعدادات.",
            .spanish: "Para proporcionar datos de velocidad y ubicación, esta aplicación necesita acceso a su ubicación. Habilítelo en Configuración.",
            .german: "Um Geschwindigkeits- und Standortdaten bereitzustellen, benötigt diese App Zugriff auf Ihren Standort. Bitte aktivieren Sie dies in den Einstellungen.",
            .french: "Pour fournir des données de vitesse et de localisation, cette application a besoin d'accéder à votre position. Veuillez l'activer dans les Paramètres.",
            .italian: "Per fornire dati su velocità e posizione, questa app necessita dell'accesso alla tua posizione. Abilitalo nelle Impostazioni.",
            .portuguese: "Para fornecer dados de velocidade e localização, este aplicativo precisa de acesso à sua localização. Ative nas Configurações.",
            .russian: "Для предоставления данных о скорости и местоположении этому приложению требуется доступ к вашему местоположению. Пожалуйста, включите его в настройках."
        ],
        "Open Settings": [
            .english: "Open Settings", .chineseTraditional: "開啟設定", .chineseSimplified: "打开设置",
            .korean: "설정 열기", .japanese: "設定を開く", .vietnamese: "Mở Cài đặt", .thai: "เปิดการตั้งค่า",
            .filipino: "Buksan ang Mga Setting", .hindi: "सेटिंग्स खोलें", .arabic: "فتح الإعدادات", .spanish: "Abrir configuración",
            .german: "Einstellungen öffnen", .french: "Ouvrir les paramètres", .italian: "Apri impostazioni", .portuguese: "Abrir Configurações", .russian: "Открыть настройки"
        ],
        
        // SettingsView
        "Language": [
            .english: "Language", .chineseTraditional: "語言", .chineseSimplified: "语言",
            .korean: "언어", .japanese: "言語", .vietnamese: "Ngôn ngữ", .thai: "ภาษา",
            .filipino: "Wika", .hindi: "भाषा", .arabic: "اللغة", .spanish: "Idioma",
            .german: "Sprache", .french: "Langue", .italian: "Lingua", .portuguese: "Idioma", .russian: "Язык"
        ],
        "Landscape": [
            .english: "Landscape", .chineseTraditional: "橫向儀表板", .chineseSimplified: "横向仪表板",
            .korean: "가로 모드", .japanese: "横向きモード", .vietnamese: "Chế độ ngang", .thai: "โหมดแนวนอน",
            .filipino: "Landscape Mode", .hindi: "लैंडस्केप मोड", .arabic: "الوضع الأفقي", .spanish: "Modo horizontal",
            .german: "Querformat", .french: "Mode paysage", .italian: "Modalità orizzontale", .portuguese: "Modo paisagem", .russian: "Ландшафтный режим"
        ],
        "Appearance": [
            .english: "Appearance", .chineseTraditional: "外觀", .chineseSimplified: "外观",
            .korean: "화면", .japanese: "外観", .vietnamese: "Giao diện", .thai: "รูปลักษณ์",
            .filipino: "Hitsura", .hindi: "दिखावट", .arabic: "المظهر", .spanish: "Apariencia",
            .german: "Erscheinungsbild", .french: "Apparence", .italian: "Aspetto", .portuguese: "Aparência", .russian: "Внешний вид"
        ],
        "Haptics": [
            .english: "Haptics", .chineseTraditional: "觸覺回饋", .chineseSimplified: "触觉回馈",
            .korean: "햅틱", .japanese: "触覚", .vietnamese: "Xúc giác", .thai: "การตอบสนองแบบสั่น",
            .filipino: "Haptics", .hindi: "हैप्टिक्स", .arabic: "اللمسات", .spanish: "Háptica",
            .german: "Haptik", .french: "Haptique", .italian: "Feedback aptico", .portuguese: "Háptica", .russian: "Тактильный отклик"
        ],
        "Haptic Feedback": [
            .english: "Haptic Feedback", .chineseTraditional: "按鈕觸覺回饋", .chineseSimplified: "按钮触觉回馈",
            .korean: "햅틱 피드백", .japanese: "触覚フィードバック", .vietnamese: "Phản hồi xúc giác", .thai: "การตอบสนองแบบสั่น",
            .filipino: "Haptic Feedback", .hindi: "हैप्टिक फीडबैक", .arabic: "ردود الفعل اللمسية", .spanish: "Vibración háptica",
            .german: "Haptisches Feedback", .french: "Retour haptique", .italian: "Feedback aptico", .portuguese: "Feedback háptico", .russian: "Тактильная обратная связь"
        ],
        "Haptic Feedback Description": [
            .english: "Provides physical feedback when interacting with buttons and settings.",
            .chineseTraditional: "在操作按鈕與設定時提供實體震動回饋。",
            .chineseSimplified: "在操作按钮与设置时提供实体震动回馈。",
            .korean: "버튼 및 설정과 상호 작용할 때 물리적 피드백을 제공합니다.",
            .japanese: "ボタンや設定を操作するときに物理的なフィードバックを提供します。",
            .vietnamese: "Cung cấp phản hồi vật lý khi tương tác với các nút và cài đặt.",
            .thai: "ให้การตอบสนองทางกายภาพเมื่อโต้ตอบกับปุ่มและการตั้งค่า",
            .filipino: "Nagbibigay ng pisikal na feedback kapag nakikipag-ugnayan sa mga button at setting.",
            .hindi: "बटन और सेटिंग्स के साथ बातचीत करते समय भौतिक प्रतिक्रिया प्रदान करता है।",
            .arabic: "يوفر ردود فعل مادية عند التفاعل مع الأزرار والإعدادات.",
            .spanish: "Proporciona retroalimentación física al interactuar con botones y ajustes.",
            .german: "Bietet physisches Feedback bei der Interaktion mit Tasten und Einstellungen.",
            .french: "Fournit un retour physique lors de l'interaction avec les boutons et les paramètres.",
            .italian: "Fornisce un feedback fisico quando si interagisce con pulsanti e impostazioni.",
            .portuguese: "Fornece feedback físico ao interagir com botões e configurações.",
            .russian: "Обеспечивает физическую обратную связь при взаимодействии с кнопками и настройками."
        ],
        "Show Top Bar": [
            .english: "Show Top Bar", .chineseTraditional: "顯示頂部資訊列", .chineseSimplified: "显示顶部信息栏",
            .korean: "상단 바 표시", .japanese: "トップバーを表示", .vietnamese: "Hiện thanh trên cùng", .thai: "แสดงแถบด้านบน",
            .filipino: "Ipakita ang Top Bar", .hindi: "शीर्ष पट्टी दिखाएं", .arabic: "إظهار الشريط العلوي", .spanish: "Mostrar barra superior",
            .german: "Obere Leiste anzeigen", .french: "Afficher la barre supérieure", .italian: "Mostra barra superiore", .portuguese: "Mostrar barra superior", .russian: "Показать верхнюю панель"
        ],
        "Reduce speed immediately": [
            .english: "Reduce speed immediately", .chineseTraditional: "立即減速", .chineseSimplified: "立即减速",
            .korean: "즉시 속도를 줄이세요", .japanese: "すぐに減速してください", .vietnamese: "Giảm tốc độ ngay lập tức", .thai: "ลดความเร็วทันที",
            .filipino: "Bawasan ang bilis agad", .hindi: "तुरंत गति कम करें", .arabic: "خفف السرعة فورا", .spanish: "Reduzca la velocidad inmediatamente",
            .german: "Geschwindigkeit sofort reduzieren", .french: "Réduisez immédiatement la vitesse", .italian: "Riduci immediatamente la velocità", .portuguese: "Reduza a velocidade imediatamente", .russian: "Немедленно снизьте скорость"
        ],
        "Theme": [
            .english: "Theme", .chineseTraditional: "主題", .chineseSimplified: "主题",
            .korean: "테마", .japanese: "テーマ", .vietnamese: "Chủ đề", .thai: "ธีม",
            .filipino: "Tema", .hindi: "थीम", .arabic: "السمة", .spanish: "Tema",
            .german: "Design", .french: "Thème", .italian: "Tema", .portuguese: "Tema", .russian: "Тема"
        ],
        "System": [
            .english: "System", .chineseTraditional: "系統預設", .chineseSimplified: "系统默认",
            .korean: "시스템", .japanese: "システム", .vietnamese: "Hệ thống", .thai: "ระบบ",
            .filipino: "Sistema", .hindi: "सिस्टम", .arabic: "النظام", .spanish: "Sistema",
            .german: "System", .french: "Système", .italian: "Sistema", .portuguese: "Sistema", .russian: "Система"
        ],
        "Light": [
            .english: "Light", .chineseTraditional: "淺色", .chineseSimplified: "浅色",
            .korean: "라이트", .japanese: "ライト", .vietnamese: "Sáng", .thai: "สว่าง",
            .filipino: "Maliwanag", .hindi: "लाइट", .arabic: "فاتح", .spanish: "Claro",
            .german: "Hell", .french: "Clair", .italian: "Chiaro", .portuguese: "Claro", .russian: "Светлая"
        ],
        "Dark": [
            .english: "Dark", .chineseTraditional: "深色", .chineseSimplified: "深色",
            .korean: "다크", .japanese: "ダーク", .vietnamese: "Tối", .thai: "มืด",
            .filipino: "Madilim", .hindi: "डार्क", .arabic: "داكن", .spanish: "Oscuro",
            .german: "Dunkel", .french: "Sombre", .italian: "Scuro", .portuguese: "Escuro", .russian: "Темная"
        ],
        "Digital": [
            .english: "Digital", .chineseTraditional: "數位儀表板", .chineseSimplified: "数位仪表板",
            .korean: "디지털 모드", .japanese: "デジタルモード", .vietnamese: "Chế độ kỹ thuật số", .thai: "โหมดดิจิตอล",
            .filipino: "Digital Mode", .hindi: "डिजिटल मोड", .arabic: "الوضع الرقمي", .spanish: "Modo digital",
            .german: "Digitalmodus", .french: "Mode numérique", .italian: "Modalità digitale", .portuguese: "Modo digital", .russian: "Цифровой режим"
        ],
        "Analog": [
            .english: "Analog", .chineseTraditional: "指針儀表板", .chineseSimplified: "指针仪表板",
            .korean: "아날로그 모드", .japanese: "アナログモード", .vietnamese: "Chế độ tương tự", .thai: "โหมดอนาล็อก",
            .filipino: "Analog Mode", .hindi: "एनालॉग मोड", .arabic: "الوضع التناظري", .spanish: "Modo analógico",
            .german: "Analogmodus", .french: "Mode analogique", .italian: "Modalità analogica", .portuguese: "Modo analógico", .russian: "Аналоговый режим"
        ],
        "Particle Effects": [
            .english: "Particle Effects", .chineseTraditional: "粒子特效", .chineseSimplified: "粒子特效",
            .korean: "입자 효과", .japanese: "パーティクル効果", .vietnamese: "Hiệu ứng hạt", .thai: "เอฟเฟกต์อนุภาค",
            .filipino: "Mga Epekto ng Particle", .hindi: "कण प्रभाव", .arabic: "تأثيرات الجسيمات", .spanish: "Efectos de partículas",
            .german: "Partikeleffekte", .french: "Effets de particules", .italian: "Effetti particellari", .portuguese: "Efeitos de partículas", .russian: "Эффекты частиц"
        ],
        "Effect Style": [
            .english: "Effect Style", .chineseTraditional: "特效樣式", .chineseSimplified: "特效样式",
            .korean: "효과 스타일", .japanese: "効果スタイル", .vietnamese: "Kiểu hiệu ứng", .thai: "รูปแบบเอฟเฟกต์",
            .filipino: "Estilo ng Epekto", .hindi: "प्रभाव शैली", .arabic: "نمط التأثير", .spanish: "Estilo de efecto",
            .german: "Effektstil", .french: "Style d'effet", .italian: "Stile effetto", .portuguese: "Estilo de efeito", .russian: "Стиль эффекта"
        ],
        "Off": [
            .english: "Off", .chineseTraditional: "關閉", .chineseSimplified: "关闭",
            .korean: "끄기", .japanese: "オフ", .vietnamese: "Tắt", .thai: "ปิด",
            .filipino: "Naka-off", .hindi: "बंद", .arabic: "إيقاف", .spanish: "Apagado",
            .german: "Aus", .french: "Désactivé", .italian: "Spento", .portuguese: "Desligado", .russian: "Выкл"
        ],
        "Orbit": [
            .english: "Orbit", .chineseTraditional: "軌道", .chineseSimplified: "轨道",
            .korean: "궤도", .japanese: "軌道", .vietnamese: "Quỹ đạo", .thai: "วงโคจร",
            .filipino: "Orbit", .hindi: "कक्षा", .arabic: "مدار", .spanish: "Órbita",
            .german: "Orbit", .french: "Orbite", .italian: "Orbita", .portuguese: "Órbita", .russian: "Орбита"
        ],
        "Gradient": [
            .english: "Gradient", .chineseTraditional: "漸層", .chineseSimplified: "渐变",
            .korean: "그라디언트", .japanese: "グラデーション", .vietnamese: "Gradient", .thai: "ไล่ระดับสี",
            .filipino: "Gradient", .hindi: "ग्रेडिएंट", .arabic: "تدرج", .spanish: "Degradado",
            .german: "Verlauf", .french: "Dégradé", .italian: "Sfumatura", .portuguese: "Gradiente", .russian: "Градиент"
        ],
        "Units": [
            .english: "Units", .chineseTraditional: "單位", .chineseSimplified: "单位",
            .korean: "단위", .japanese: "單位", .vietnamese: "Đơn vị", .thai: "หน่วย",
            .filipino: "Mga Yunit", .hindi: "इकाइयाँ", .arabic: "الوحدات", .spanish: "Unidades",
            .german: "Einheiten", .french: "Unités", .italian: "Unità", .portuguese: "Unidades", .russian: "Единицы"
        ],
        "Use Metric": [
            .english: "Use Metric (km/h, km)", .chineseTraditional: "使用公制 (km/h, km)", .chineseSimplified: "使用公制 (km/h, km)",
            .korean: "미터법 사용 (km/h, km)", .japanese: "メートル法を使用 (km/h, km)", .vietnamese: "Dùng hệ mét (km/h, km)", .thai: "ใช้ระบบเมตริก (km/h, km)",
            .filipino: "Gamitin ang Metric (km/h, km)", .hindi: "मीट्रिक का उपयोग करें (km/h, km)", .arabic: "استخدام النظام المتري (كم/س، كم)", .spanish: "Usar métrico (km/h, km)",
            .german: "Metrisch verwenden (km/h, km)", .french: "Utiliser le sistema métrique", .italian: "Usa metrico (km/h, km)", .portuguese: "Usar métrico (km/h, km)", .russian: "Использовать метрическую (км/ч, км)"
        ],
        "Metric Description": [
            .english: "Speed in km/h, distance in km/m", .chineseTraditional: "速度顯示 km/h，距離顯示 km/m", .chineseSimplified: "速度显示 km/h，距离显示 km/m",
            .korean: "속도는 km/h, 거리는 km/m로 표시", .japanese: "速度はkm/h、距離はkm/m", .vietnamese: "Tốc độ km/h, khoảng cách km/m", .thai: "ความเร็วเป็น km/h, ระยะทางเป็น km/m",
            .filipino: "Bilis sa km/h, distansya sa km/m", .hindi: "गति km/h में, दूरी km/m में", .arabic: "السرعة بـ كم/س، المسافة بـ كم/م", .spanish: "Velocidad en km/h, distancia en km/m",
            .german: "Geschwindigkeit in km/h, Distanz in km/m", .french: "Vitesse en km/h, distance en km/m", .italian: "Velocità in km/h, distanza in km/m", .portuguese: "Velocidade em km/h, distância em km/m", .russian: "Скорость в км/ч, расстояние в км/м"
        ],
        "Imperial Description": [
            .english: "Speed in mph, distance in mi/ft", .chineseTraditional: "速度顯示 mph，距離顯示 mi/ft",  .chineseSimplified: "速度显示 mph，距离显示 mi/ft",
            .korean: "속도는 mph, 거리는 mi/ft로 표시", .japanese: "速度はmph、距離はmi/ft", .vietnamese: "Tốc độ mph, khoảng cách mi/ft", .thai: "ความเร็วเป็น mph, ระยะทางเป็น mi/ft",
            .filipino: "Bilis sa mph, distansya sa mi/ft", .hindi: "गति mph में, दूरी mi/ft में", .arabic: "السرعة بـ ميل/س، المسافة بـ ميل/قدم", .spanish: "Velocidad en mph, distancia en mi/ft",
            .german: "Geschwindigkeit in mph, Distanz in mi/ft", .french: "Vitesse en mph, distance en mi/ft", .italian: "Velocità in mph, distanza in mi/ft", .portuguese: "Velocidade em mph, distância em mi/ft", .russian: "Скорость в миль/ч, расстояние в милях/футах"
        ],
        "Trip": [
            .english: "Trip", .chineseTraditional: "行程", .chineseSimplified: "行程",
            .korean: "여행", .japanese: "トリップ", .vietnamese: "Chuyến đi", .thai: "การเดินทาง",
            .filipino: "Biyahe", .hindi: "यात्रा", .arabic: "رحلة", .spanish: "Viaje",
            .german: "Fahrt", .french: "Trajet", .italian: "Viaggio", .portuguese: "Viagem", .russian: "Поездка"
        ],
        "Distance": [
            .english: "Distance", .chineseTraditional: "距離", .chineseSimplified: "距离",
            .korean: "거리", .japanese: "距離", .vietnamese: "Khoảng cách", .thai: "ระยะทาง",
            .filipino: "Distansya", .hindi: "दूरी", .arabic: "المسافة", .spanish: "Distancia",
            .german: "Distanz", .french: "Distance", .italian: "Distanza", .portuguese: "Distância", .russian: "Расстояние"
        ],
        "Reset Trip": [
            .english: "Reset Trip", .chineseTraditional: "重置行程", .chineseSimplified: "重置行程",
            .korean: "여행 초기화", .japanese: "トリップをリセット", .vietnamese: "Đặt lại chuyến đi", .thai: "รีเซ็ตการเดินทาง",
            .filipino: "I-reset ang Biyahe", .hindi: "यात्रा रीसेट करें", .arabic: "إعادة تعيين الرحلة", .spanish: "Reiniciar viaje",
            .german: "Fahrt zurücksetzen", .french: "Réinitialiser le trajet", .italian: "Reimposta viaggio", .portuguese: "Reiniciar viagem", .russian: "Сбросить поездку"
        ],
        "Choose how your current speed is visualized on the main screen.": [
            .english: "Choose how your current speed is visualized on the main screen.",
            .chineseTraditional: "選擇如何在主畫面上顯示您的當前速度。",
            .chineseSimplified: "选择如何在主屏幕上显示您的当前速度。",
            .korean: "메인 화면에서 현재 속도가 어떻게 시각화되는지 선택하세요.",
            .japanese: "メイン画面で現在の速度がどのように表示されるかを選択してください。",
            .vietnamese: "Chọn cách hiển thị tốc độ hiện tại của bạn",
            .thai: "เลือกวิธีการแสดงความเร็วปัจจุบันของคุณบนหน้าจอหลัก",
            .filipino: "Piliin kung paano ipinapakita ang iyong kasalukuyang bilis sa pangunahing screen.",
            .hindi: "मुख्य स्क्रीन पर आपकी वर्तमान गति कैसे प्रदर्शित होती है, यह चुनें।",
            .arabic: "اختر كيفية عرض سرعتك الحالية على الشاشة الرئيسية.",
            .spanish: "Elija cómo se visualiza su velocidad actual en la pantalla principal.",
            .german: "Wählen Sie, wie Ihre aktuelle Geschwindigkeit auf dem Hauptbildschirm visualisiert wird.",
            .french: "Choisissez comment votre vitesse actuelle est visualisée sur l'écran principal.",
            .italian: "Scegli come viene visualizzata la tua velocità attuale sulla schermata principale.",
            .portuguese: "Escolha como sua velocidade atual é visualizada na tela principal.",
            .russian: "Выберите, как ваша текущая скорость отображается на главном экране."
        ],
        "Speed Camera Alerts": [
            .english: "Speed Camera Alerts", .chineseTraditional: "測速照相警示", .chineseSimplified: "测速照相警示",
            .korean: "과속 단속 카메라 알림", .japanese: "スピードカメラアラート", .vietnamese: "Cảnh báo camera tốc độ", .thai: "แจ้งเตือนกล้องตรวจจับความเร็ว",
            .filipino: "Mga Alerto ng Speed Camera", .hindi: "स्पीड कैमरा अलर्ट", .arabic: "تنبيهات كاميرا السرعة", .spanish: "Alertas de cámara de velocidad",
            .german: "Blitzerwarnungen", .french: "Alertes radars", .italian: "Avvisi autovelox", .portuguese: "Alertas de radar", .russian: "Оповещения о камерах"
        ],
        "Infinite Proximity": [
            .english: "Infinite Proximity", .chineseTraditional: "無限偵測距離", .chineseSimplified: "无限检测距离",
            .korean: "무한 근접", .japanese: "無限近接", .vietnamese: "Phạm vi vô hạn", .thai: "ระยะใกล้ไม่จำกัด",
            .filipino: "Walang Hangganang Proximity", .hindi: "अनंत निकटता", .arabic: "قرب لا نهائي", .spanish: "Proximidad infinita",
            .german: "Unendliche Nähe", .french: "Proximité infinie", .italian: "Prossimità infinita", .portuguese: "Proximidade infinita", .russian: "Бесконечная близость"
        ],
        "Infinite Proximity On": [
            .english: "Will always show the absolute closest speed camera, regardless of distance",
            .chineseTraditional: "無論距離多遠，總是顯示最近的測速照相",
            .chineseSimplified: "无论距离多远，总是显示最近的测速照相",
            .korean: "거리에 관계없이 항상 가장 가까운 과속 단속 카메라를 표시합니다",
            .japanese: "距離に関係なく、常に最も近いスピードカメラを表示します",
            .vietnamese: "Sẽ luôn hiển thị camera tốc độ gần nhất tuyệt đối, bất kể khoảng cách",
            .thai: "จะแสดงกล้องตรวจจับความเร็วที่ใกล้ที่สุดเสมอ ไม่ว่าจะระยะทางเท่าใด",
            .filipino: "Palaging ipapakita ang pinakamalapit na speed camera, anuman ang distansya",
            .hindi: "दूरी की परवाह किए बिना, हमेशा सबसे निकटतम स्पीड कैमरा दिखाएगा",
            .arabic: "سيظهر دائمًا أقرب كاميرا سرعة، بغض النظر عن المسافة",
            .spanish: "Siempre mostrará la cámara de velocidad más cercana, sin importar la distancia",
            .german: "Zeigt immer den absolut nächsten Blitzer an, unabhängig von der Entfernung",
            .french: "Affichera toujours le radar le plus proche, quelle que soit la distance",
            .italian: "Mostrerà sempre l'autovelox più vicino, indipendentemente dalla distanza",
            .portuguese: "Sempre mostrará o radar mais próximo, independentemente da distância",
            .russian: "Всегда будет показывать ближайшую камеру, независимо от расстояния"
        ],
        "Infinite Proximity Off": [
            .english: "Only shows speed cameras within 2km", .chineseTraditional: "僅顯示 2 公里內的測速照相", .chineseSimplified: "仅显示 2 公里内的测速照相",
            .korean: "2km 이내의 과속 단속 카메라만 표시", .japanese: "2km以内のスピードカメラのみ表示", .vietnamese: "Chỉ hiển thị camera tốc độ trong vòng 2km", .thai: "แสดงเฉพาะกล้องตรวจจับความเร็วภายใน 2 กม.",
            .filipino: "Nagpapakita lamang ng mga speed camera sa loob ng 2km", .hindi: "केवल 2 किमी के भीतर स्पीड कैमरे दिखाता है", .arabic: "يظهر فقط كاميرات السرعة في نطاق 2 كم", .spanish: "Solo muestra cámaras dentro de 2 km",
            .german: "Zeigt nur Blitzer im Umkreis von 2 km an", .french: "Affiche uniquement les radars à moins de 2 km", .italian: "Mostra solo autovelox entro 2 km", .portuguese: "Mostra apenas radares num raio de 2 km", .russian: "Показывает камеры только в радиусе 2 км"
        ],
        "Alert Distance": [
            .english: "Alert Distance", .chineseTraditional: "警示距離", .chineseSimplified: "警示距离",
            .korean: "알림 거리", .japanese: "アラート距離", .vietnamese: "Khoảng cách cảnh báo", .thai: "ระยะแจ้งเตือน",
            .filipino: "Distansya ng Alerto", .hindi: "चेतावनी दूरी", .arabic: "مسافة التنبيه", .spanish: "Distancia de alerta",
            .german: "Warndistanz", .french: "Distance d'alerte", .italian: "Distanza avviso", .portuguese: "Distância de alerta", .russian: "Дистанция оповещения"
        ],
        "Alert Distance Description": [
            .english: "You'll be alerted when within this distance of a speed camera",
            .chineseTraditional: "當進入此距離範圍內時將發出警示",
            .chineseSimplified: "当进入此距离范围时将发出警示",
            .korean: "과속 단속 카메라가 이 거리 내에 있으면 알림을 받습니다",
            .japanese: "スピードカメラがこの距離内にある場合にアラートが表示されます",
            .vietnamese: "Bạn sẽ được cảnh báo khi ở trong khoảng cách này của camera tốc độ",
            .thai: "คุณจะได้รับการแจ้งเตือนเมื่ออยู่ในระยะนี้ของกล้องตรวจจับความเร็ว",
            .filipino: "Aalertuhan ka kapag nasa loob ng distansyang ito ng isang speed camera",
            .hindi: "स्पीड कैमरा की इस दूरी के भीतर होने पर आपको सचेत किया जाएगा",
            .arabic: "سيتم تنبيهك عندما تكون ضمن هذه المسافة من كاميرا السرعة",
            .spanish: "Se le alertará cuando esté dentro de esta distancia de una cámara de velocidad",
            .german: "Sie werden gewarnt, wenn Sie sich in dieser Entfernung zu einem Blitzer befinden",
            .french: "Vous serez alerté lorsque vous serez à cette distance d'un radar",
            .italian: "Verrai avvisato quando sarai entro questa distanza da un autovelox",
            .portuguese: "Você será alertado quando estiver dentro desta distância de um radar",
            .russian: "Вы получите оповещение, когда окажетесь на этом расстоянии от камеры"
        ],
        "Alert Sound": [
            .english: "Alert Sound", .chineseTraditional: "警示音效", .chineseSimplified: "警示音效",
            .korean: "알림 소리", .japanese: "アラート音", .vietnamese: "Âm thanh cảnh báo", .thai: "เสียงแจ้งเตือน",
            .filipino: "Tunog ng Alerto", .hindi: "चेतावनी ध्वनि", .arabic: "صوت التنبيه", .spanish: "Sonido de alerta",
            .german: "Warnton", .french: "Son d'alerte", .italian: "Suono avviso", .portuguese: "Som de alerta", .russian: "Звук оповещения"
        ],
        "Navigation Pop": [
            .english: "Navigation Pop", .chineseTraditional: "導航提示音", .chineseSimplified: "导航提示音",
            .korean: "내비게이션 팝", .japanese: "ナビゲーションポップ", .vietnamese: "Tiếng pop điều hướng", .thai: "เสียงป๊อปนำทาง",
            .filipino: "Navigation Pop", .hindi: "नेविगेशन पॉप", .arabic: "نقرة التنقل", .spanish: "Pop de navegación",
            .german: "Navigations-Pop", .french: "Pop de navigation", .italian: "Pop navigazione", .portuguese: "Pop de navegação", .russian: "Навигационный поп"
        ],
        "Soft Chime": [
            .english: "Soft Chime", .chineseTraditional: "柔和鐘聲", .chineseSimplified: "柔和钟声",
            .korean: "부드러운 차임", .japanese: "ソフトチャイム", .vietnamese: "Chuông nhẹ", .thai: "เสียงระฆังเบาๆ",
            .filipino: "Malambot na Chime", .hindi: "सॉफ्ट चाइम", .arabic: "رنين ناعم", .spanish: "Campanilla suave",
            .german: "Sanfter Gong", .french: "Carillon doux", .italian: "Rintocco dolce", .portuguese: "Carrilhão suave", .russian: "Мягкий звон"
        ],
        "Modern": [
            .english: "Modern", .chineseTraditional: "現代", .chineseSimplified: "现代",
            .korean: "모던", .japanese: "モダン", .vietnamese: "Hiện đại", .thai: "ทันสมัย",
            .filipino: "Moderno", .hindi: "आधुनिक", .arabic: "حديث", .spanish: "Moderno",
            .german: "Modern", .french: "Moderne", .italian: "Moderno", .portuguese: "Moderno", .russian: "Современный"
        ],
        "Bloom": [
            .english: "Bloom", .chineseTraditional: "綻放", .chineseSimplified: "绽放",
            .korean: "블룸", .japanese: "ブルーム", .vietnamese: "Nở hoa", .thai: "บานสะพรั่ง",
            .filipino: "Bloom", .hindi: "ब्लूम", .arabic: "إزهار", .spanish: "Florecer",
            .german: "Blüte", .french: "Éclosion", .italian: "Fioritura", .portuguese: "Florescer", .russian: "Цветение"
        ],
        "Chord": [
            .english: "Chord", .chineseTraditional: "和弦", .chineseSimplified: "和弦",
            .korean: "코드", .japanese: "コード", .vietnamese: "Hợp âm", .thai: "คอร์ด",
            .filipino: "Chord", .hindi: "जीवा", .arabic: "وتر", .spanish: "Acorde",
            .german: "Akkord", .french: "Accord", .italian: "Accordo", .portuguese: "Acorde", .russian: "Аккорд"
        ],
        "Pop (Mac-like)": [
            .english: "Pop (Mac-like)", .chineseTraditional: "波普 (Mac 風格)", .chineseSimplified: "波普 (Mac 风格)",
            .korean: "팝 (Mac 스타일)", .japanese: "ポップ (Mac風)", .vietnamese: "Pop (Kiểu Mac)", .thai: "ป๊อป (สไตล์ Mac)",
            .filipino: "Pop (Mac-like)", .hindi: "पॉप (Mac जैसा)", .arabic: "بوب (نمط Mac)", .spanish: "Pop (estilo Mac)",
            .german: "Pop (Mac-Stil)", .french: "Pop (Style Mac)", .italian: "Pop (stile Mac)", .portuguese: "Pop (estilo Mac)", .russian: "Поп (в стиле Mac)"
        ],
        "Subtle Click": [
            .english: "Subtle Click", .chineseTraditional: "微妙點擊", .chineseSimplified: "微妙点击",
            .korean: "미묘한 클릭", .japanese: "微妙なクリック", .vietnamese: "Nhấp chuột tinh tế", .thai: "คลิกเบาๆ",
            .filipino: "Subtle Click", .hindi: "हल्का क्लिक", .arabic: "نقر خفيف", .spanish: "Clic sutil",
            .german: "Dezenter Klick", .french: "Clic subtil", .italian: "Clic sottile", .portuguese: "Clique sutil", .russian: "Тонкий щелчок"
        ],
        "News Flash": [
            .english: "News Flash", .chineseTraditional: "新聞快訊", .chineseSimplified: "新闻快讯",
            .korean: "뉴스 속보", .japanese: "ニュース速報", .vietnamese: "Tin nhanh", .thai: "ข่าวด่วน",
            .filipino: "News Flash", .hindi: "समाचार फ़्लैश", .arabic: "خبر عاجل", .spanish: "Noticia de última hora",
            .german: "Eilmeldung", .french: "Flash info", .italian: "Notizie flash", .portuguese: "Notícias de última hora", .russian: "Срочные новости"
        ],
        "Positive": [
            .english: "Positive", .chineseTraditional: "積極", .chineseSimplified: "积极",
            .korean: "긍정적", .japanese: "ポジティブ", .vietnamese: "Tích cực", .thai: "เชิงบวก",
            .filipino: "Positibo", .hindi: "सकारात्मक", .arabic: "إيجابي", .spanish: "Positivo",
            .german: "Positiv", .french: "Positif", .italian: "Positivo", .portuguese: "Positivo", .russian: "Позитивный"
        ],
        "Sound": [
            .english: "Sound", .chineseTraditional: "音效", .chineseSimplified: "音效",
            .korean: "소리", .japanese: "サウンド", .vietnamese: "Âm thanh", .thai: "เสียง",
            .filipino: "Tunog", .hindi: "ध्वनि", .arabic: "الصوت", .spanish: "Sonido",
            .german: "Sound", .french: "Son", .italian: "Suono", .portuguese: "Som", .russian: "Звук"
        ],
        "Alarm Sound": [
            .english: "Alarm Sound", .chineseTraditional: "警報音效", .chineseSimplified: "警报音效",
            .korean: "알람 소리", .japanese: "アラーム音", .vietnamese: "Âm thanh báo động", .thai: "เสียงแจ้งเตือน",
            .filipino: "Tunog ng Alarm", .hindi: "अलार्म ध्वनि", .arabic: "صوت التنبيه", .spanish: "Sonido de alarma",
            .german: "Alarmton", .french: "Son d'alarme", .italian: "Suono allarme", .portuguese: "Som de alarme", .russian: "Звук будильника"
        ],
        "Volume": [
            .english: "Volume", .chineseTraditional: "音量", .chineseSimplified: "音量",
            .korean: "볼륨", .japanese: "音量", .vietnamese: "Âm lượng", .thai: "ระดับเสียง",
            .filipino: "Volume", .hindi: "वॉल्यूम", .arabic: "الصوت", .spanish: "Volumen",
            .german: "Lautstärke", .french: "Volume", .italian: "Volume", .portuguese: "Volume", .russian: "Громкость"
        ],
        "Volume Description": [
            .english: "Adjusts the alert sound volume. 100% is normal volume; up to 200% for louder alerts.",
            .chineseTraditional: "調整警報音量。100% 為正常音量；最高可調至 200% 使警報更響亮。",
            .chineseSimplified: "调整警报音量。100% 为正常音量；最高可调至 200% 使警报更响亮。",
            .korean: "알람 소리 음량을 조절합니다. 100%가 기본 볼륨이며 최대 200%까지 높일 수 있습니다.",
            .japanese: "アラート音の音量を調整します。100% が通常音量、最大 200% まで大きくできます。",
            .vietnamese: "Điều chỉnh âm lượng cảnh báo. 100% là âm lượng bình thường; tối đa 200% để cảnh báo to hơn.",
            .thai: "ปรับระดับเสียงแจ้งเตือน 100% คือเสียงปกติ สูงสุดถึง 200% เพื่อเสียงดังขึ้น",
            .filipino: "Inaayos ang volume ng tunog ng alerto. 100% ang normal na volume; hanggang 200% para sa mas malakas na alerto.",
            .hindi: "अलर्ट ध्वनि वॉल्यूम समायोजित करता है। 100% सामान्य वॉल्यूम है; तेज़ अलर्ट के लिए 200% तक।",
            .arabic: "يضبط مستوى صوت التنبيه. 100% هو الصوت الطبيعي; حتى 200% للحصول على تنبيهات أعلى.",
            .spanish: "Ajusta el volumen del sonido de alerta. 100% es el volumen normal; hasta 200% para alertas más altas.",
            .german: "Passt die Lautstärke des Alarmtons an. 100% ist die normale Lautstärke; bis zu 200% für lautere Alarme.",
            .french: "Règle le volume du son d'alerte. 100% est le volume normal; jusqu'à 200% pour des alertes plus fortes.",
            .italian: "Regola il volume del suono di avviso. Il 100% è il volume normale; fino al 200% per avvisi più forti.",
            .portuguese: "Ajusta o volume do som de alerta. 100% é o volume normal; até 200% para alertas mais altos.",
            .russian: "Регулирует громкость звука оповещения. 100% — нормальная громкость; до 200% для более громких оповещений."
        ],
        "Default": [
            .english: "Default", .chineseTraditional: "預設", .chineseSimplified: "默认",
            .korean: "기본", .japanese: "デフォルト", .vietnamese: "Mặc định", .thai: "ค่าเริ่มต้น",
            .filipino: "Default", .hindi: "डिफ़ॉल्ट", .arabic: "افتراضي", .spanish: "Predeterminado",
            .german: "Standard", .french: "Par défaut", .italian: "Predefinito", .portuguese: "Padrão", .russian: "По умолчанию"
        ],
        "Chime": [
            .english: "Chime", .chineseTraditional: "鈴聲", .chineseSimplified: "铃声",
            .korean: "차임", .japanese: "チャイム", .vietnamese: "Chuông", .thai: "เสียงระฆัง",
            .filipino: "Chime", .hindi: "चाइम", .arabic: "رنين", .spanish: "Campanilla",
            .german: "Gong", .french: "Carillon", .italian: "Rintocco", .portuguese: "Carrilhão", .russian: "Звон"
        ],
        "Pace": [
            .english: "Pace", .chineseTraditional: "節奏", .chineseSimplified: "节奏",
            .korean: "페이스", .japanese: "ペース", .vietnamese: "Nhịp", .thai: "จังหวะ",
            .filipino: "Pace", .hindi: "पेस", .arabic: "إيقاع", .spanish: "Ritmo",
            .german: "Rhythmus", .french: "Cadence", .italian: "Ritmo", .portuguese: "Ritmo", .russian: "Темп"
        ],
        "Ding": [
            .english: "Ding", .chineseTraditional: "叮", .chineseSimplified: "叮",
            .korean: "딩", .japanese: "ディン", .vietnamese: "Ding", .thai: "ดิ้ง",
            .filipino: "Ding", .hindi: "डिंग", .arabic: "دنق", .spanish: "Din",
            .german: "Ding", .french: "Ding", .italian: "Ding", .portuguese: "Ding", .russian: "Динь"
        ],
        "Other Settings": [
            .english: "Other Settings", .chineseTraditional: "其他設定", .chineseSimplified: "其他设置",
            .korean: "기타 설정", .japanese: "その他の設定", .vietnamese: "Cài đặt khác", .thai: "การตั้งค่าอื่นๆ",
            .filipino: "Iba pang Mga Setting", .hindi: "अन्य सेटिंग्स", .arabic: "إعدادات أخرى", .spanish: "Otras configuraciones",
            .german: "Andere Einstellungen", .french: "Autres paramètres", .italian: "Altre impostazioni", .portuguese: "Outras configurações", .russian: "Другие настройки"
        ],
        "Picture in Picture": [
            .english: "Picture in Picture", .chineseTraditional: "子母畫面", .chineseSimplified: "画中画",
            .korean: "화면 속 화면", .japanese: "ピクチャ イン ピクチャ", .vietnamese: "Hình trong hình", .thai: "ภาพในภาพ",
            .filipino: "Picture in Picture", .hindi: "पिक्चर इन पिक्चर", .arabic: "صورة داخل صورة", .spanish: "Imagen en imagen",
            .german: "Bild in Bild", .french: "Incrustation vidéo", .italian: "Immagine nell'immagine", .portuguese: "Imagem em imagem", .russian: "Картинка в картинке"
        ],
        "Picture in Picture Description": [
            .english: "Speed overlay floats on top of other apps when you switch away.",
            .chineseTraditional: "切換到其他 App 時，速度視窗將懸浮在上方。",
            .chineseSimplified: "切换到其他 App 时，速度浮窗将悬浮在上方。",
            .korean: "다른 앱으로 전환 시 속도 오버레이가 위에 표시됩니다.",
            .japanese: "他のアプリに切り替えると速度ウィジェットが上に表示されます。",
            .vietnamese: "Lớp tốc độ nổi trên các ứng dụng khác khi bạn chuyển đổi.",
            .thai: "แสดงความเร็วลอยอยู่เหนือแอปอื่นเมื่อคุณสลับออกไป",
            .filipino: "Ang overlay ng bilis ay lulutang sa ibabaw ng ibang apps kapag lumipat ka.",
            .hindi: "दूसरे ऐप पर जाने पर स्पीड ओवरले ऊपर तैरता है।",
            .arabic: "تظهر نافذة السرعة فوق التطبيقات الأخرى عند التبديل.",
            .spanish: "La velocidad flota sobre otras apps al cambiar de aplicación.",
            .german: "Die Geschwindigkeitsanzeige schwebt über anderen Apps beim Wechsel.",
            .french: "L'affichage de la vitesse flotte au-dessus des autres apps lors du changement.",
            .italian: "La velocità fluttua sopra le altre app quando passi ad esse.",
            .portuguese: "A velocidade flutua sobre outros apps ao trocar de aplicativo.",
            .russian: "Оверлей скорости отображается поверх других приложений при переключении."
        ],
        "Show Tutorial": [
            .english: "Show Tutorial", .chineseTraditional: "顯示教學", .chineseSimplified: "显示教程",
            .korean: "튜토리얼 보기", .japanese: "チュートリアルを表示", .vietnamese: "Hiện hướng dẫn", .thai: "顯示教程",
            .filipino: "Ipakita ang Tutorial", .hindi: "ट्यूटोरियल दिखाएं", .arabic: "عرض البرنامج التعليمي", .spanish: "Mostrar tutorial",
            .german: "Tutorial anzeigen", .french: "Afficher le tutoriel", .italian: "Mostra tutorial", .portuguese: "Mostrar tutorial", .russian: "Показать обучение"
        ],
        
        "Track Speed Desc": [
            .english: "See your current speed in real-time with dynamic color effects that change color based on acceleration",
            .chineseTraditional: "即時查看當前速度，搭配隨加速度變色的動態特效",
            .chineseSimplified: "实时查看当前速度，搭配随加速度变色的动态特效",
            .korean: "가속도에 따라 색상이 변하는 동적 효과로 현재 속도를 실시간으로 확인하세요",
            .japanese: "加速度に基づいて色が変化する動的な効果で、現在の速度をリアルタイムで確認できます",
            .vietnamese: "Xem tốc độ hiện tại của bạn trong thời gian thực với các hiệu ứng động thay đổi màu sắc dựa trên gia tốc",
            .thai: "ดูความเร็วปัจจุบันของคุณแบบเรียลไทม์ด้วยเอฟเฟกต์ไดนามิกที่เปลี่ยนสีตามความเร่ง",
            .filipino: "Tingnan ang iyong kasalukuyang bilis sa real-time na may mga dynamic na epekto na nagbabago ng kulay batay sa acceleration",
            .hindi: "त्वरण के आधार पर रंग बदलने वाले गतिशील प्रभावों के साथ वास्तविक समय में अपनी वर्तमान गति देखें",
            .arabic: "شاهد سرعتك الحالية في الوقت الفعلي مع تأثيرات الديناميكية التي تغير اللون بناءً على التسارع",
            .spanish: "Vea su velocidad actual en tiempo real con efectos dinámicos que cambian de color según la aceleración",
            .german: "Sehen Sie Ihre aktuelle Geschwindigkeit in Echtzeit mit dynamischen Effekten, die je nach Beschleunigung die Farbe ändern",
            .french: "Voyez votre velocità actuelle en temps réel avec des effets dynamiques qui changent de couleur en fonction de l'accélération",
            .italian: "Vedi la tua velocità attuale in tempo reale con effetti dinamici che cambiano colore in base all'accelerazione",
            .portuguese: "Veja sua velocità atual em tempo real com efeitos dinâmicos que mudam de cor com base na aceleração",
            .russian: "Смотрите текущую скорость в реальном времени с динамическими эффектами, меняющими цвет при ускорении"
        ],

        "Speed Display": [
            .english: "Speed Display", .chineseTraditional: "速度顯示", .chineseSimplified: "速度显示",
            .korean: "속도 표시", .japanese: "速度表示", .vietnamese: "Hiển thị tốc độ", .thai: "การแสดงความเร็ว",
            .filipino: "Pagpapakita ng Bilis", .hindi: "गति प्रदर्शन", .arabic: "عرض السرعة", .spanish: "Pantalla de velocidad",
            .german: "Geschwindigkeitsanzeige", .french: "Affichage de la velocità", .italian: "Display della velocità", .portuguese: "Exibição de velocidade", .russian: "Отображение скорости"
        ],

        "Speed Display Mode": [
            .english: "Speed Display Mode", .chineseTraditional: "速度顯示模式", .chineseSimplified: "速度显示模式",
            .korean: "속도 표시 모드", .japanese: "速度表示モード", .vietnamese: "Chế độ hiển thị tốc độ", .thai: "โหมดการแสดงความเร็ว",
            .filipino: "Mode ng Pagpapakita ng Bilis", .hindi: "गति प्रदर्शन मोड", .arabic: "وضع عرض السرعة", .spanish: "Modo de pantalla de velocidad",
            .german: "Geschwindigkeitsanzeigemodus", .french: "Mode d'affichage de la velocità", .italian: "Modalità di visualizzazione della velocità", .portuguese: "Modo de exibição de velocidade", .russian: "Режим отображения скорости"
        ],
        
        // SpeedTrapListView
        "Nearest Speed Cameras": [
            .english: "Nearest Speed Cameras", .chineseTraditional: "附近測速照相", .chineseSimplified: "附近测速照相",
            .korean: "가장 가까운 과속 단속 카메라", .japanese: "最寄りのスピードカメラ", .vietnamese: "Camera tốc độ gần nhất", .thai: "กล้องตรวจจับความเร็วที่ใกล้ที่สุด",
            .filipino: "Pinakamalapit na Speed Cameras", .hindi: "निकटतम स्पीड कैमरे", .arabic: "أقرب كاميرات السرعة", .spanish: "Cámaras de velocità más cercanas",
            .german: "Nächste Blitzer", .french: "Radars les plus proches", .italian: "Autovelox più vicini", .portuguese: "Radares mais próximos", .russian: "Ближайшие камеры"
        ],
        
        // Onboarding
        "Track Your Speed": [
            .english: "Track Your Speed", .chineseTraditional: "追蹤速度", .chineseSimplified: "追踪速度",
            .korean: "속도 추적", .japanese: "速度を追跡", .vietnamese: "Theo dõi tốc độ của bạn", .thai: "ติดตามความเร็วของคุณ",
            .filipino: "Subaybayan ang Iyong Bilis", .hindi: "अपनी गति ट्रैक करें", .arabic: "تتبع سرعتك", .spanish: "Rastrea tu velocidad",
            .german: "Verfolgen Sie Ihre Geschwindigkeit", .french: "Suivez votre velocità", .italian: "Traccia la tua velocità", .portuguese: "Rastreie sua velocità", .russian: "Отслеживайте скорость"
        ],
        "View Your Route": [
            .english: "View Your Route", .chineseTraditional: "查看路線", .chineseSimplified: "查看路线",
            .korean: "경로 보기", .japanese: "ルートを表示", .vietnamese: "Xem lộ trình của bạn", .thai: "ดูเส้นทางของคุณ",
            .filipino: "Tingnan ang Iyong Ruta", .hindi: "अपना मार्ग देखें", .arabic: "عرض مسارك", .spanish: "Ver su ruta",
            .german: "Ihre Route anzeigen", .french: "Voir votre itinéraire", .italian: "Vedi il tuo percorso", .portuguese: "Ver sua rota", .russian: "Просмотр маршрута"
        ],
        "View Route Desc": [
            .english: "Tap the map button to see your location on the map. Use the X button to exit map view",
            .chineseTraditional: "點擊地圖按鈕查看您的位置。使用 X 按鈕退出地圖視圖",
            .chineseSimplified: "点击地图按钮查看您的位置。使用 X 按钮退出地图视图",
            .korean: "지도 버튼을 탭하여 지도에서 위치를 확인하세요. 지도 보기를 종료하려면 X 버튼을 사용하세요",
            .japanese: "マップボタンをタップして、マップ上の位置を確認します。マップビューを終了するにはXボタンを使用します",
            .vietnamese: "Nhấn vào nút bản đồ để xem vị trí của bạn trên bản đồ. Sử dụng nút X để thoát chế độ xem bản đồ",
            .thai: "แตะปุ่มแผนที่เพื่อดูตำแหน่งของคุณบนแผนที่ ใช้ปุ่ม X เพื่อออกจากมุมมองแผนที่",
            .filipino: "I-tap ang pindutan ng mapa upang makita ang iyong lokasyon sa mapa. Gamitin ang X button upang lumabas sa view ng mapa",
            .hindi: "मानचित्र पर अपना स्थान देखने के लिए मानचित्र बटन पर टैप करें। मानचित्र दृश्य से बाहर निकलने के लिए X बटन का उपयोग करें",
            .arabic: "اضغط على زر الخريطة لرؤية موقعك على الخريطة. استخدم زر X للخروج من عرض الخريطة",
            .spanish: "Toque el botón del mapa para ver su ubicación en el mapa. Use el botón X para salir de la vista del mapa",
            .german: "Tippen Sie auf die Kartenschaltfläche, um Ihren Standort auf der Karte zu sehen. Verwenden Sie die X-Taste, um die Kartenansicht zu verlassen",
            .french: "Appuyez sur le bouton de la carte pour voir votre position sur la carte. Utilisez le bouton X pour quitter la vue carte",
            .italian: "Tocca il pulsante della mappa per vedere la tua posizione sulla mappa. Usa il pulsante X per uscire dalla visualizzazione mappa",
            .portuguese: "Toque no botão do mapa para ver sua localização no mapa. Use o botão X para sair da visualização do mapa",
            .russian: "Нажмите кнопку карты, чтобы увидеть свое местоположение. Используйте кнопку X для выхода"
        ],
        "Speed Cameras": [
            .english: "Speed Cameras", .chineseTraditional: "測速照相", .chineseSimplified: "测速照相",
            .korean: "과속 단속 카메라", .japanese: "スピードカメラ", .vietnamese: "Camera tốc độ", .thai: "กล้องตรวจจับความเร็ว",
            .filipino: "Mga Speed Camera", .hindi: "स्पीड कैमरे", .arabic: "كاميرات السرعة", .spanish: "Cámaras de velocità",
            .german: "Blitzer", .french: "Radars", .italian: "Autovelox", .portuguese: "Radares", .russian: "Камеры скорости"
        ],
        "Speed Cameras Desc": [
            .english: "Tap the camera button to see a list of the nearest speed cameras and their distances",
            .chineseTraditional: "點擊相機按鈕查看最近的測速照相列表及其距離",
            .chineseSimplified: "点击相机按钮查看最近的测速照相列表及其距离",
            .korean: "카메라 버튼을 탭하여 가장 가까운 과속 단속 카메라 목록과 거리를 확인하세요",
            .japanese: "カメラボタンをタップして、最寄りのスピードカメラとその距離のリストを表示します",
            .vietnamese: "Nhấn vào nút máy ảnh để xem danh sách các camera tốc độ gần nhất và khoảng cách của chúng",
            .thai: "แตะปุ่มกล้องเพื่อดูรายการกล้องตรวจจับความเร็วที่ใกล้ที่สุดและระยะทาง",
            .filipino: "I-tap ang pindutan ng camera upang makita ang isang listahan ng pinakamalapit na mga speed camera at ang kanilang mga distansya",
            .hindi: "निकटतम स्पीड कैमरों और उनकी दूरी की सूची देखने के लिए कैमरा बटन पर टैप करें",
            .arabic: "اضغط على زر الكاميرا לרؤية قائمة بأقرب كاميرات السرعة ومسافاتها",
            .spanish: "Toque el botón de la cámara para ver una lista de las cámaras de velocidad más cercanas y sus distancias",
            .german: "Tippen Sie auf die Kameraschaltfläche, um eine Liste der nächsten Blitzer und deren Entfernungen anzuzeigen",
            .french: "Appuyez sur le bouton de la caméra pour voir une liste des radars les plus proches et leurs distances",
            .italian: "Tocca il pulsante della fotocamera per vedere un elenco degli autovelox più vicini e le loro distanze",
            .portuguese: "Toque no botão da câmera para ver uma lista dos radares mais próximos e suas distâncias",
            .russian: "Нажмите кнопку камеры, чтобы увидеть список ближайших камер и расстояние до них"
        ],
        "Customize Settings": [
            .english: "Customize Settings", .chineseTraditional: "自訂設定", .chineseSimplified: "自定义设置",
            .korean: "설정 사용자 지정", .japanese: "設定をカスタマイズ", .vietnamese: "Tùy chỉnh Cài đặt", .thai: "ปรับแต่งการตั้งค่า",
            .filipino: "I-customize ang Mga Setting", .hindi: "सेटिंग्स अनुकूलित करें", .arabic: "تخصيص الإعدادات", .spanish: "Personalizar configuración",
            .german: "Einstellungen anpassen", .french: "Personnaliser les paramètres", .italian: "Personalizza impostazioni", .portuguese: "Personalizar configurações", .russian: "Настроить параметры"
        ],
        "Customize Settings Desc": [
            .english: "Access settings to switch between metric/imperial units, change theme, view trip stats, and reset your trip",
            .chineseTraditional: "進入設定切換公制/英制單位、更改主題、查看行程統計和重置行程",
            .chineseSimplified: "进入设置切换公制/英制单位、更改主题、查看行程统计和重置行程",
            .korean: "설정에 액세스하여 미터법/야드파운드법 단위를 전환하고, 테마를 변경하고, 여행 통계를 보고, 여행을 초기화하세요",
            .japanese: "設定にアクセスして、メートル法/ヤード・ポンド法単位の切り替え、テーマの変更、トリップ統計の表示、トリップのリセットを行います",
            .vietnamese: "Truy cập cài đặt để chuyển đổi giữa các đơn vị mét/imperial, thay đổi chủ đề, xem thống kê chuyến đi và đặt lại chuyến đi của bạn",
            .thai: "เข้าถึงการตั้งค่าเพื่อสลับระหว่างหน่วยเมตริก/อิมพีเรียล เปลี่ยนธีม ดูสถิติการเดินทาง และรีเซ็ตการเดินทางของคุณ",
            .filipino: "I-access ang mga setting upang lumipat sa pagitan ng metric/imperial units, baguhin ang tema, tingnan ang stats ng biyahe, at i-reset ang iyong biyahe",
            .hindi: "मीट्रिक/इंपीरियल इकाइयों के बीच स्विच करने, थीम बदलने, यात्रा के आंकड़े देखने और अपनी यात्रा को रीसेट करने के लिए सेटिंग्स तक पहुंचें",
            .arabic: "الوصول إلى الإعدادات للتبديل بين الوحدات المترية/الإمبراطورية، وتغيير السمة، وعرض إحصائيات الرحلة، وإعادة تعيين رحلتك",
            .spanish: "Acceda a la configuración para cambiar entre unidades métricas/imperiales, cambiar el tema, ver estadísticas de viaje y reiniciar su viaje",
            .german: "Greifen Sie auf die Einstellungen zu, um zwischen metrischen/imperialen Einheiten zu wechseln, das Design zu ändern, Fahrtstatistiken anzuzeigen und Ihre Fahrt zurückzusetzen",
            .french: "Accédez aux paramètres pour basculer entre les unités métriques/impériales, changer de thème, voir les statistiques du trajet et réinitialiser votre trajet",
            .italian: "Accedi alle impostazioni per passare tra unità metriche/imperiali, cambiare tema, visualizzare le statistiche di viaggio e reimpostare il viaggio",
            .portuguese: "Acesse as configurações para alternar entre unidades métricas/imperiais, alterar o tema, ver estatísticas da viagem e reiniciar sua viagem",
            .russian: "Зайдите в настройки, чтобы переключить единицы измерения, изменить тему, просмотреть статистику и сбросить поездку"
        ],
        "Trip Information": [
            .english: "Trip Information", .chineseTraditional: "行程資訊", .chineseSimplified: "行程信息",
            .korean: "여행 정보", .japanese: "トリップ情報", .vietnamese: "Thông tin chuyến đi", .thai: "ข้อมูลการเดินทาง",
            .filipino: "Impormasyon ng Biyahe", .hindi: "यात्रा की जानकारी", .arabic: "معلومات الرحلة", .spanish: "Información del viaje",
            .german: "Fahrtinformationen", .french: "Informations sur le trajet", .italian: "Informazioni viaggio", .portuguese: "Informações da viagem", .russian: "Информация о поездке"
        ],
        "Trip Info Desc": [
            .english: "When stopped, you'll see your current street, trip distance, max speed, and battery level",
            .chineseTraditional: "停止時，您將看到當前街道、行程距離、最高速度和電池電量",
            .chineseSimplified: "停止时，您将看到当前街道、行程距离、最高速度和电池电量",
            .korean: "정지 시 현재 거리, 주행 거리, 최고 속도 및 배터리 잔량을 볼 수 있습니다",
            .japanese: "停止中は、現在の通り、走行距離、最高速度、バッテリー残量が表示されます",
            .vietnamese: "Khi dừng lại, bạn sẽ thấy đường hiện tại, quãng đường chuyến đi, tốc độ tối đa và mức pin",
            .thai: "เมื่อหยุด คุณจะเห็นถนนปัจจุบัน ระยะทางทริป ความเร็วสูงสุด และระดับแบตเตอรี่",
            .filipino: "Kapag huminto, makikita mo ang iyong kasalukuyang kalye, distansya ng biyahe, pinakamabilis, at antas ng baterya",
            .hindi: "रुकने पर, आप अपनी वर्तमान सड़क, यात्रा की दूरी, अधिकतम गति और बैटरी स्तर देखेंगे",
            .arabic: "عند التوقف، سترى شارعك الحالي، ومسافة الرحلة، والسرعة القصوى، ومستوى البطارية",
            .spanish: "Cuando se detenga, verá su calle actual, la distanza del viaje, la velocità máxima y el nivel de la batería",
            .german: "Im Stand sehen Sie Ihre aktuelle Straße, Reisedistanz, Höchstgeschwindigkeit und Batteriestand",
            .french: "À l'arrêt, vous verrez votre rue actuelle, la distance du trajet, la velocità maximale et le niveau de la batterie",
            .italian: "Quando sei fermo, vedrai la tua strada attuale, la distanza del viaggio, la velocità massima e il livello della batteria",
            .portuguese: "Quando parado, você verá sua rua atual, distanza da viagem, velocità máxima e nível da bateria",
            .russian: "При остановке вы увидите текущую улицу, расстояние, макс. скорость и уровень заряда"
        ],
        "Horizontal Dashboard": [
            .english: "Horizontal Dashboard", .chineseTraditional: "橫向儀表板", .chineseSimplified: "横向仪表板",
            .korean: "가로 대시보드", .japanese: "横向きダッシュボード", .vietnamese: "Bảng điều khiển ngang", .thai: "แดชบอร์ดแนวนอน",
            .filipino: "Horizontal na Dashboard", .hindi: "क्षैतिज डैशबोर्ड", .arabic: "لوحة القيادة الأفقية", .spanish: "Panel horizontal",
            .german: "Horizontales Dashboard", .french: "Tableau de bord horizontal", .italian: "Dashboard orizzontale", .portuguese: "Painel horizontal", .russian: "Горизонтальная панель"
        ],
        "Horizontal Dash Desc": [
            .english: "Rotate to landscape for a wide-screen view with speed, stats, and quick controls side by side",
            .chineseTraditional: "旋轉為橫向模式，以寬螢幕顯示速度、統計數據與快速控制",
            .chineseSimplified: "旋转至横向模式，以宽屏显示速度、统计数据和快速控制",
            .korean: "가로 모드로 회전하면 속도, 통계 및 빠른 제어를 나란히 넓은 화면으로 볼 수 있습니다",
            .japanese: "横向きに回転すると、速度・統計・クイックコントロールを横並びのワイドスクリーンで表示します",
            .vietnamese: "Xoay sang chế độ ngang để xem màn hình rộng với tốc độ, số liệu thống kê và điều khiển nhanh",
            .thai: "หมุนเป็นแนวนอนเพื่อดูหน้าจอกว้างพร้อมความเร็ว สถิติ และตัวควบคุมด่วนแบบเคียงข้าง",
            .filipino: "I-rotate sa landscape para sa wide-screen view na may bilis, stats, at mabilis na mga kontrol nang magkatabi",
            .hindi: "वाइड-स्क्रीन व्यू के लिए लैंडस्केप में घुमाएं जिसमें गति, आँकड़े और त्वरित नियंत्रण एक साथ दिखें",
            .arabic: "أدر الشاشة أفقيًا للحصول على عرض واسع مع السرعة والإحصائيات والأدوات جنبًا إلى جنب",
            .spanish: "Gire a horizontal para una vista panorámica con velocidad, estadísticas y controles rápidos juntos",
            .german: "Drehen Sie ins Querformat für eine Weitwinkelansicht mit Geschwindigkeit, Statistiken und Schnellsteuerung",
            .french: "Faites pivoter en paysage pour une vue large avec la vitesse, les stats et les commandes côte à côte",
            .italian: "Ruota in orizzontale per una vista panoramica con velocità, statistiche e controlli rapidi affiancati",
            .portuguese: "Gire para paisagem para uma visão ampla com velocidade, estatísticas e controles rápidos",
            .russian: "Поверните в альбомный режим для широкоэкранного вида со скоростью, статистикой и быстрым управлением"
        ],

        // New Onboarding Keys
        "Speed Display Modes": [
            .english: "Speed Display Modes", .chineseTraditional: "速度顯示模式", .chineseSimplified: "速度显示模式",
            .korean: "속도 표시 모드", .japanese: "速度表示モード", .vietnamese: "Chế độ hiển thị tốc độ", .thai: "โหมดแสดงความเร็ว",
            .filipino: "Mga Mode ng Pagpapakita ng Bilis", .hindi: "गति प्रदर्शन मोड", .arabic: "أوضاع عرض السرعة", .spanish: "Modos de pantalla de velocidad",
            .german: "Geschwindigkeitsmodi", .french: "Modes d'affichage", .italian: "Modalità velocità", .portuguese: "Modos de velocidade", .russian: "Режимы скорости"
        ],
        "Speed Display Modes Desc": [
            .english: "Choose between a clean digital readout or a classic analog gauge to display your speed",
            .chineseTraditional: "在數位顯示和指針儀表之間選擇您的速度顯示方式",
            .chineseSimplified: "在数字显示和指针仪表之间选择您的速度显示方式",
            .korean: "깔끔한 디지털 표시 또는 클래식 아날로그 계기판 중에서 속도 표시 방식을 선택하세요",
            .japanese: "すっきりしたデジタル表示またはクラシックなアナログメーターで速度を表示します",
            .vietnamese: "Chọn giữa màn hình kỹ thuật số gọn gàng hoặc đồng hồ tương tự cổ điển để hiển thị tốc độ",
            .thai: "เลือกระหว่างจอแสดงผลดิจิตอลที่ชัดเจนหรือมาตรวัดอนาล็อกแบบคลาสสิก",
            .filipino: "Pumili sa pagitan ng malinis na digital readout o klasikong analog gauge para sa iyong bilis",
            .hindi: "अपनी गति प्रदर्शित करने के लिए एक साफ डिजिटल रीडआउट या क्लासिक एनालॉग गेज में से चुनें",
            .arabic: "اختر بين شاشة رقمية نظيفة أو عداد تناظري كلاسيكي لعرض سرعتك",
            .spanish: "Elija entre una lectura digital limpia o un indicador analógico clásico",
            .german: "Wählen Sie zwischen einer digitalen oder klassischen Analoganzeige für Ihre Geschwindigkeit",
            .french: "Choisissez entre un affichage numérique épuré ou un indicateur analogique classique",
            .italian: "Scegli tra una lettura digitale pulita o un indicatore analogico classico",
            .portuguese: "Escolha entre uma leitura digital limpa ou um manômetro analógico clássico",
            .russian: "Выберите между цифровым дисплеем или классическим аналоговым спидометром"
        ],
        "Digital Mode": [
            .english: "Digital Mode", .chineseTraditional: "數位模式", .chineseSimplified: "数字模式",
            .korean: "디지털 모드", .japanese: "デジタルモード", .vietnamese: "Chế độ kỹ thuật số", .thai: "โหมดดิจิตอล",
            .filipino: "Digital Mode", .hindi: "डिजिटल मोड", .arabic: "الوضع الرقمي", .spanish: "Modo digital",
            .german: "Digitalmodus", .french: "Mode numérique", .italian: "Modalità digitale", .portuguese: "Modo digital", .russian: "Цифровой режим"
        ],
        "Analog Mode": [
            .english: "Analog Mode", .chineseTraditional: "指針模式", .chineseSimplified: "指针模式",
            .korean: "아날로그 모드", .japanese: "アナログモード", .vietnamese: "Chế độ tương tự", .thai: "โหมดอนาล็อก",
            .filipino: "Analog Mode", .hindi: "एनालॉग मोड", .arabic: "الوضع التناظري", .spanish: "Modo analógico",
            .german: "Analogmodus", .french: "Mode analogique", .italian: "Modalità analogica", .portuguese: "Modo analógico", .russian: "Аналоговый режим"
        ],
        "Distraction Alert Desc": [
            .english: "Uses face tracking to detect when you're looking at your phone while driving fast, then alerts you to keep eyes on the road",
            .chineseTraditional: "使用臉部追蹤偵測您在高速行駛時是否注視手機，並提醒您專注於路況",
            .chineseSimplified: "使用面部追踪检测您在高速行驶时是否注视手机，并提醒您专注于路况",
            .korean: "고속 주행 중 휴대폰을 보고 있는지 감지하고 전방 주시를 알리는 얼굴 추적 사용",
            .japanese: "高速走行中に画面を見ているかを顔追跡で検出し、前方注視を促します",
            .vietnamese: "Sử dụng theo dõi khuôn mặt để phát hiện khi bạn nhìn điện thoại lúc lái xe nhanh",
            .thai: "ใช้การติดตามใบหน้าเพื่อตรวจจับเมื่อคุณมองหน้าจอขณะขับรถเร็ว",
            .filipino: "Gumagamit ng face tracking upang matukoy kung tumitingin ka sa telepono habang mabilis ang pagmamaneho",
            .hindi: "तेज गति से गाड़ी चलाते समय फ़ोन देखने पर फेस ट्रैकिंग से पता लगाकर सचेत करता है",
            .arabic: "يستخدم تتبع الوجه لاكتشاف ما إذا كنت تنظر إلى هاتفك أثناء القيادة السريعة",
            .spanish: "Usa seguimiento facial para detectar si miras el teléfono al conducir rápido y te alerta",
            .german: "Erkennt mithilfe der Gesichtsverfolgung, ob Sie während der Fahrt auf Ihr Telefon schauen",
            .french: "Utilise le suivi du visage pour détecter si vous regardez votre téléphone en conduisant",
            .italian: "Usa il rilevamento del volto per capire se guardi il telefono mentre guidi velocemente",
            .portuguese: "Usa rastreamento facial para detectar se você está olhando para o telefone enquanto dirige",
            .russian: "Отслеживает лицо, чтобы определить, смотрите ли вы на телефон во время быстрой езды"
        ],
        "Face Tracking": [
            .english: "Face Tracking", .chineseTraditional: "臉部追蹤", .chineseSimplified: "面部追踪",
            .korean: "얼굴 추적", .japanese: "顔追跡", .vietnamese: "Theo dõi khuôn mặt", .thai: "ติดตามใบหน้า",
            .filipino: "Face Tracking", .hindi: "फेस ट्रैकिंग", .arabic: "تتبع الوجه", .spanish: "Seguimiento facial",
            .german: "Gesichtsverfolgung", .french: "Suivi du visage", .italian: "Rilevamento volto", .portuguese: "Rastreamento facial", .russian: "Отслеживание лица"
        ],
        "Speed Aware": [
            .english: "Speed Aware", .chineseTraditional: "速度感知", .chineseSimplified: "速度感知",
            .korean: "속도 인식", .japanese: "速度感知", .vietnamese: "Nhận biết tốc độ", .thai: "ตรวจจับความเร็ว",
            .filipino: "Speed Aware", .hindi: "गति जागरूक", .arabic: "واعٍ للسرعة", .spanish: "Consciente de velocidad",
            .german: "Geschwindigkeitsbewusst", .french: "Sensible à la vitesse", .italian: "Rilevamento velocità", .portuguese: "Velocidade detectada", .russian: "Контроль скорости"
        ],
        "Live Activity": [
            .english: "Live Activity", .chineseTraditional: "即時活動", .chineseSimplified: "即时活动",
            .korean: "실시간 활동", .japanese: "ライブアクティビティ", .vietnamese: "Hoạt động trực tiếp", .thai: "กิจกรรมสด",
            .filipino: "Live Activity", .hindi: "लाइव एक्टिविटी", .arabic: "النشاط المباشر", .spanish: "Actividad en vivo",
            .german: "Live Activity", .french: "Activité en direct", .italian: "Attività live", .portuguese: "Atividade ao vivo", .russian: "Живая активность"
        ],
        "Live Activity Desc": [
            .english: "Your speed is displayed on your Lock Screen and in the Dynamic Island while the app runs in the background",
            .chineseTraditional: "應用程式在背景執行時，速度會顯示在鎖定畫面和動態島上",
            .chineseSimplified: "应用程序在后台运行时，速度将显示在锁定屏幕和灵动岛上",
            .korean: "앱이 백그라운드에서 실행되는 동안 잠금 화면과 Dynamic Island에 속도가 표시됩니다",
            .japanese: "アプリがバックグラウンドで動作中に、速度がロック画面とDynamic Islandに表示されます",
            .vietnamese: "Tốc độ của bạn được hiển thị trên Màn hình khóa và Dynamic Island khi ứng dụng chạy nền",
            .thai: "ความเร็วของคุณแสดงบนหน้าจอล็อคและ Dynamic Island ขณะแอปทำงานเบื้องหลัง",
            .filipino: "Ang iyong bilis ay ipinapakita sa Lock Screen at Dynamic Island habang nagtatakbo ang app sa background",
            .hindi: "ऐप बैकग्राउंड में चलते समय आपकी गति लॉक स्क्रीन और Dynamic Island पर दिखती है",
            .arabic: "تظهر سرعتك على شاشة القفل وفي الجزيرة الديناميكية أثناء تشغيل التطبيق في الخلفية",
            .spanish: "Tu velocidad se muestra en la pantalla de bloqueo y en la Isla Dinámica mientras la app corre en segundo plano",
            .german: "Ihre Geschwindigkeit wird auf dem Sperrbildschirm und in der Dynamic Island angezeigt, während die App im Hintergrund läuft",
            .french: "Votre vitesse est affichée sur l'écran de verrouillage et dans la Dynamic Island pendant que l'app tourne en arrière-plan",
            .italian: "La tua velocità viene mostrata sulla schermata di blocco e nella Dynamic Island mentre l'app è in background",
            .portuguese: "Sua velocidade é exibida na tela de bloqueio e na Ilha Dinâmica enquanto o app roda em segundo plano",
            .russian: "Ваша скорость отображается на экране блокировки и в Dynamic Island, пока приложение работает в фоне"
        ],
        "Lock Screen": [
            .english: "Lock Screen", .chineseTraditional: "鎖定畫面", .chineseSimplified: "锁定屏幕",
            .korean: "잠금 화면", .japanese: "ロック画面", .vietnamese: "Màn hình khóa", .thai: "หน้าจอล็อค",
            .filipino: "Lock Screen", .hindi: "लॉक स्क्रीन", .arabic: "شاشة القفل", .spanish: "Pantalla de bloqueo",
            .german: "Sperrbildschirm", .french: "Écran de verrouillage", .italian: "Schermata di blocco", .portuguese: "Tela de bloqueio", .russian: "Экран блокировки"
        ],
        "Dynamic Island": [
            .english: "Dynamic Island", .chineseTraditional: "動態島", .chineseSimplified: "灵动岛",
            .korean: "Dynamic Island", .japanese: "Dynamic Island", .vietnamese: "Đảo Động", .thai: "ไดนามิกไอส์แลนด์",
            .filipino: "Dynamic Island", .hindi: "डायनामिक आइलैंड", .arabic: "الجزيرة الديناميكية", .spanish: "Isla Dinámica",
            .german: "Dynamic Island", .french: "Dynamic Island", .italian: "Dynamic Island", .portuguese: "Ilha Dinâmica", .russian: "Dynamic Island"
        ],
        "Audio Alert": [
            .english: "Audio Alert", .chineseTraditional: "音頻警示", .chineseSimplified: "音频警示",
            .korean: "오디오 알림", .japanese: "音声アラート", .vietnamese: "Cảnh báo âm thanh", .thai: "แจ้งเตือนเสียง",
            .filipino: "Audio Alert", .hindi: "ऑडियो अलर्ट", .arabic: "تنبيه صوتي", .spanish: "Alerta de audio",
            .german: "Audiowarnung", .french: "Alerte sonore", .italian: "Avviso audio", .portuguese: "Alerta sonoro", .russian: "Звуковое оповещение"
        ],
        "Proximity Alert": [
            .english: "Proximity Alert", .chineseTraditional: "接近警示", .chineseSimplified: "接近警示",
            .korean: "근접 경고", .japanese: "近接アラート", .vietnamese: "Cảnh báo gần", .thai: "แจ้งเตือนระยะใกล้",
            .filipino: "Proximity Alert", .hindi: "निकटता अलर्ट", .arabic: "تنبيه القرب", .spanish: "Alerta de proximidad",
            .german: "Näherungswarnung", .french: "Alerte de proximité", .italian: "Avviso di prossimità", .portuguese: "Alerta de proximidade", .russian: "Оповещение о близости"
        ],
        "Rotate device for landscape view": [
            .english: "Rotate device for landscape view", .chineseTraditional: "旋轉裝置以使用橫向模式", .chineseSimplified: "旋转设备以使用横向模式",
            .korean: "기기를 회전하여 가로 보기 사용", .japanese: "デバイスを回転して横向き表示", .vietnamese: "Xoay thiết bị cho chế độ ngang", .thai: "หมุนอุปกรณ์เพื่อโหมดแนวนอน",
            .filipino: "I-rotate ang device para sa landscape view", .hindi: "लैंडस्केप व्यू के लिए डिवाइस घुमाएं", .arabic: "اقلب الجهاز للعرض الأفقي", .spanish: "Gire el dispositivo para vista horizontal",
            .german: "Gerät drehen für Querformat", .french: "Tournez l'appareil pour la vue paysage", .italian: "Ruota il dispositivo per la vista orizzontale", .portuguese: "Gire o dispositivo para vista paisagem", .russian: "Поверните устройство для горизонтального вида"
        ],

        // Distraction Alert
        "Distraction Alert": [
            .english: "Distraction Alert", .chineseTraditional: "分心警示", .chineseSimplified: "分心警示",
            .korean: "주의 산만 경고", .japanese: "わき見運転アラート", .vietnamese: "Cảnh báo mất tập trung", .thai: "แจ้งเตือนการเสียสมาธิ",
            .filipino: "Alerto sa Pagkakaabala", .hindi: "ध्यान भटकाने की चेतावनी", .arabic: "تنبيه تشتت الانتباه", .spanish: "Alerta de distracción",
            .german: "Ablenkungswarnung", .french: "Alerte de distraction", .italian: "Avviso distrazione", .portuguese: "Alerta de distração", .russian: "Предупреждение об отвлечении"
        ],
        "Face tracking is not supported on this device.": [
            .english: "Face tracking is not supported on this device.", .chineseTraditional: "此裝置不支援臉部追蹤。", .chineseSimplified: "此设备不支持面部追踪。",
            .korean: "이 기기에서는 얼굴 추적을 지원하지 않습니다.", .japanese: "このデバイスでは顔追跡がサポートされていません。", .vietnamese: "Theo dõi khuôn mặt không được hỗ trợ trên thiết bị này.", .thai: "อุปกรณ์นี้ไม่รองรับการติดตามใบหน้า",
            .filipino: "Hindi suportado ang pagsubaybay sa mukha sa device na ito.", .hindi: "इस डिवाइस पर फेस ट्रैकिंग समर्थित नहीं है।", .arabic: "تتبع الوجه غير مدعوم على هذا الجهاز.", .spanish: "El seguimiento facial no es compatible con este dispositivo.",
            .german: "Gesichtsverfolgung wird auf diesem Gerät nicht unterstützt.", .french: "Le suivi du visage n'est pas pris en charge sur cet appareil.", .italian: "Il rilevamento del volto non è supportato su questo dispositivo.", .portuguese: "O rastreamento facial não é suportado neste dispositivo.", .russian: "Отслеживание лица не поддерживается на этом устройстве."
        ],
        "Warns you if you look at the screen while driving fast.": [
            .english: "Warns you if you look at the screen while driving fast.",
            .chineseTraditional: "當您在高速行駛時注視螢幕將發出警告。",
            .chineseSimplified: "当您在高速行驶时注视屏幕将发出警告。",
            .korean: "고속 주행 중 화면을 보면 경고합니다.",
            .japanese: "高速走行中に画面を見ると警告します。",
            .vietnamese: "Cảnh báo bạn nếu bạn nhìn vào màn hình khi lái xe nhanh.",
            .thai: "เตือนคุณหากคุณมองหน้าจอขณะขับรถเร็ว",
            .filipino: "Nagbababala sa iyo kung tumingin ka sa screen habang mabilis ang pagmamaneho.",
            .hindi: "यदि आप तेज गति से गाड़ी चलाते समय स्क्रीन को देखते हैं तो आपको चेतावनी देता है।",
            .arabic: "يحذرك إذا نظرت إلى الشاشة أثناء القيادة بسرعة.",
            .spanish: "Le avisa si mira la pantalla mientras conduce rápido.",
            .german: "Warnt Sie, wenn Sie während der schnellen Fahrt auf den Bildschirm schauen.",
            .french: "Vous avertit si vous regardez l'écran en conduisant vite.",
            .italian: "Ti avvisa se guardi lo schermo mentre guidi velocemente.",
            .portuguese: "Avisa se você olhar para a tela enquanto dirige rápido.",
            .russian: "Предупреждает, если вы смотрите на экран при быстрой езде."
        ],
        "Eyes on the road!": [
            .english: "Eyes on the road!", .chineseTraditional: "專心開車！", .chineseSimplified: "专心开车！",
            .korean: "전방 주시!", .japanese: "前を見て！", .vietnamese: "Tập trung lái xe!", .thai: "มองถนน!",
            .filipino: "Tumingin sa kalsada!", .hindi: "सड़क पर ध्यान दें!", .arabic: "انتبه للطريق!", .spanish: "¡Ojos en la carretera!",
            .german: "Augen auf die Straße!", .french: "Regardez la route !", .italian: "Occhi sulla strada!", .portuguese: "Olhos na estrada!", .russian: "Смотрите на дорогу!"
        ],
        "Focus on driving": [
            .english: "Focus on driving", .chineseTraditional: "請專心駕駛", .chineseSimplified: "请专心驾驶",
            .korean: "운전에 집중하세요", .japanese: "運転に集中してください", .vietnamese: "Tập trung lái xe", .thai: "มีสมาธิกับการขับรถ",
            .filipino: "Mag-focus sa pagmamaneho", .hindi: "ड्राइविंग पर ध्यान दें", .arabic: "ركز على القيادة", .spanish: "Concéntrese en conducir",
            .german: "Konzentrieren Sie sich auf das Fahren", .french: "Concentrez-vous sur la conduite", .italian: "Concentrati sulla guida", .portuguese: "Concentre-se em dirigir", .russian: "Сосредоточьтесь на вождении"
        ]
    ]
    
    func localize(_ key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
}
