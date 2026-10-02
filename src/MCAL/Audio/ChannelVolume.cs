using System.Numerics;
using NAudio.CoreAudioApi;

namespace MCAL.Audio;

/// <summary>
/// Per-channel Windows endpoint volume (the Sound control panel "Levels → Balance" values) for one output device.
/// Windows keeps the master volume equal to the loudest channel, and moving the master shifts every channel by the
/// same number of dB, so a balance set here survives later volume changes. Values are system-wide and persistent.
/// </summary>
public sealed class ChannelVolume : IDisposable
{
    private readonly MMDevice device;
    private readonly AudioEndpointVolume volume;
    private readonly int[] map; // speaker channel (mix format) -> endpoint volume channel, or -1
    private readonly AudioEndpointVolumeNotificationDelegate handler;

    /// <summary>Raised on a COM thread whenever any volume on the endpoint changes (including our own changes).</summary>
    public event Action? Changed;

    public ChannelVolume(MMDevice device, int mixChannels, IReadOnlyList<SpeakerDef> speakers)
    {
        this.device = device;
        volume = device.AudioEndpointVolume;
        MinDb = Math.Max(volume.VolumeRange.MinDecibels, -60);
        MaxDb = volume.VolumeRange.MaxDecibels;

        int endpointChannels = volume.Channels.Count;
        uint deviceMask = ReadDeviceFormatMask(device);
        map = Enumerable.Repeat(-1, mixChannels).ToArray();
        foreach (var s in speakers)
        {
            if (s.Channel >= mixChannels) continue;
            if (endpointChannels == mixChannels)
                map[s.Channel] = s.Channel;
            else if (deviceMask != 0 && BitOperations.PopCount(deviceMask) == endpointChannels && (deviceMask & s.MaskBit) != 0)
                map[s.Channel] = BitOperations.PopCount(deviceMask & (s.MaskBit - 1)); // position of this speaker in the device's own format
            else if (s.Channel < endpointChannels)
                map[s.Channel] = s.Channel;
        }

        handler = _ => Changed?.Invoke();
        volume.OnVolumeNotification += handler;
    }

    public double MinDb { get; }
    public double MaxDb { get; }

    /// <summary>Master volume in dB; Windows keeps this equal to the loudest channel.</summary>
    public double MasterDb => volume.MasterVolumeLevel;

    public bool CanControl(int channel) => channel >= 0 && channel < map.Length && map[channel] >= 0;

    public double Get(int channel) => volume.Channels[map[channel]].VolumeLevel;

    public void Set(int channel, double db) =>
        volume.Channels[map[channel]].VolumeLevel = (float)Math.Clamp(db, MinDb, MaxDb);

    /// <summary>The endpoint's native format (may have more channels than the Windows speaker setup, e.g. virtual devices).</summary>
    private static uint ReadDeviceFormatMask(MMDevice device)
    {
        try
        {
            var store = device.Properties;
            var key = PropertyKeys.PKEY_AudioEngine_DeviceFormat;
            if (store.Contains(key) && store[key].Value is byte[] b && b.Length >= 24 && BitConverter.ToUInt16(b, 0) == 0xFFFE)
                return BitConverter.ToUInt32(b, 20);
        }
        catch { /* property missing or unreadable */ }
        return 0;
    }

    public void Dispose()
    {
        volume.OnVolumeNotification -= handler;
        device.Dispose();
    }
}
