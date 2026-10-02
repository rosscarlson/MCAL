using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using MCAL.Audio;
using MCAL.Theming;

namespace MCAL;

public sealed class AppSettings
{
    public ThemeChoice Theme { get; set; } = ThemeChoice.Dark;
    public string? DeviceId { get; set; }
    public SignalType Signal { get; set; } = SignalType.PinkNoise;
    public double LevelDb { get; set; } = -20;
    public double SineFrequency { get; set; } = 1000;
    public bool LfeLowPass { get; set; } = true;
    public double LfeCutoffHz { get; set; } = TestSignalProvider.DefaultLfeCutoff;
    public bool AutoCheckUpdates { get; set; } = true;

    /// <summary>MCAL applies speaker levels inside Voicemeeter (set once a Voicemeeter device has been used).</summary>
    public bool VoicemeeterEnabled { get; set; }
    public string VoicemeeterBus { get; set; } = "A1";
    /// <summary>dB per bus channel (8 per bus), keyed by bus name.</summary>
    public Dictionary<string, double[]> VoicemeeterGains { get; set; } = new();
    public bool TrayHintShown { get; set; }
    public bool CycleEnabled { get; set; }
    public int CycleSeconds { get; set; } = 4;

    public string? MicDeviceId { get; set; }

    /// <summary>Selected speakers per device, as a bitmask of channel indexes.</summary>
    public Dictionary<string, ulong> SelectionByDevice { get; set; } = new();

    public static string Folder => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "MCAL");
    private static string FilePath => Path.Combine(Folder, "settings.json");

    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter() },
    };

    public static AppSettings Load()
    {
        try
        {
            // one-time migration from the app's earlier name ("Audio Level")
            string legacy = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "AudioLevel", "settings.json");
            if (!File.Exists(FilePath) && File.Exists(legacy))
            {
                Directory.CreateDirectory(Folder);
                File.Copy(legacy, FilePath);
            }

            if (File.Exists(FilePath))
                return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(FilePath), Options) ?? new AppSettings();
        }
        catch { /* corrupt settings: fall back to defaults */ }
        return new AppSettings();
    }

    public void Save()
    {
        try
        {
            Directory.CreateDirectory(Folder);
            File.WriteAllText(FilePath, JsonSerializer.Serialize(this, Options));
        }
        catch { /* non-fatal */ }
    }
}
