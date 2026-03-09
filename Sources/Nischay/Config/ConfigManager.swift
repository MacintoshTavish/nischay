import Foundation

/// Persistent configuration for the Nischay app.
/// Mirrors the ConfigManager ivar set found in the RE class dump.
/// All values persist via UserDefaults.
class ConfigManager: @unchecked Sendable {
    static let shared = ConfigManager()
    private let defaults = UserDefaults.standard

    // MARK: - API Config (placeholders – fill in after setting up Supabase / OpenAI)

    var supabaseURL: String {
        get { defaults.string(forKey: "supabaseURL") ?? "" }
        set { defaults.set(newValue, forKey: "supabaseURL") }
    }

    var supabaseAnonKey: String {
        get { defaults.string(forKey: "supabaseAnonKey") ?? "" }
        set { defaults.set(newValue, forKey: "supabaseAnonKey") }
    }

    var openAIAPIKey: String {
        get { defaults.string(forKey: "openAIAPIKey") ?? "" }
        set { defaults.set(newValue, forKey: "openAIAPIKey") }
    }

    var openAIModel: String {
        get { defaults.string(forKey: "openAIModel") ?? "gpt-4o" }
        set { defaults.set(newValue, forKey: "openAIModel") }
    }

    var maxTokens: Int {
        get { defaults.integer(forKey: "maxTokens") == 0 ? 2000 : defaults.integer(forKey: "maxTokens") }
        set { defaults.set(newValue, forKey: "maxTokens") }
    }

    var temperature: Double {
        get {
            let v = defaults.double(forKey: "temperature")
            return v == 0 ? 0.7 : v
        }
        set { defaults.set(newValue, forKey: "temperature") }
    }

    // MARK: - Feature Flags

    /// When true, screen analysis goes via Supabase Edge Function; else uses local OpenAI key.
    var useEdgeFunctionAPI: Bool {
        get { defaults.bool(forKey: "useEdgeFunctionAPI") }
        set { defaults.set(newValue, forKey: "useEdgeFunctionAPI") }
    }

    var debugMode: Bool {
        get { defaults.bool(forKey: "debugMode") }
        set { defaults.set(newValue, forKey: "debugMode") }
    }

    /// When true, send screenshot image to Vision API instead of OCR text only.
    var useVisionMode: Bool {
        get { defaults.bool(forKey: "useVisionMode") }
        set { defaults.set(newValue, forKey: "useVisionMode") }
    }

    /// Ultra-fast mode: higher frame rate capture.
    var ultraFastMode: Bool {
        get { defaults.bool(forKey: "ultraFastMode") }
        set { defaults.set(newValue, forKey: "ultraFastMode") }
    }

    var isShortAnswerMode: Bool {
        get { defaults.bool(forKey: "isShortAnswerMode") }
        set { defaults.set(newValue, forKey: "isShortAnswerMode") }
    }

    // MARK: - UI

    var windowTransparency: Double {
        get {
            let v = defaults.double(forKey: "windowTransparency")
            return v == 0 ? 1.0 : v
        }
        set { defaults.set(newValue, forKey: "windowTransparency") }
    }

    // MARK: - Capture / OCR

    /// Interval (seconds) between OCR passes on the captured frame.
    var ocrInterval: Double {
        get {
            let v = defaults.double(forKey: "ocrInterval")
            return v == 0 ? 2.0 : v
        }
        set { defaults.set(newValue, forKey: "ocrInterval") }
    }

    var minTextLength: Int {
        get { defaults.integer(forKey: "minTextLength") == 0 ? 10 : defaults.integer(forKey: "minTextLength") }
        set { defaults.set(newValue, forKey: "minTextLength") }
    }

    // MARK: - Chat

    var maxSavedMessages: Int {
        get { defaults.integer(forKey: "maxSavedMessages") == 0 ? 100 : defaults.integer(forKey: "maxSavedMessages") }
        set { defaults.set(newValue, forKey: "maxSavedMessages") }
    }

    private init() {}
}
