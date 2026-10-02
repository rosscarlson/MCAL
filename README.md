# MCAL — Multi Channel Audio Leveler

A Windows app for leveling stereo and surround speakers. Pick an output device and MCAL shows that device's actual
speaker layout (stereo / quad / 5.1 / 7.1 / 7.1.4 …, as configured in Windows Sound settings). It plays a calibrated
test signal on any speakers you choose. You can set each speaker's level by hand with a knob, or automatically with a
microphone.

**Download:** the latest installer is on the [Releases](https://github.com/rosscarlson/MCAL/releases/latest) page.
Once installed, MCAL checks for new versions on its own.

## Features

- **Speaker map** built from the device's channel layout. If the layout is unknown, a numbered channel grid is shown.
- **Test signals:** pink noise (full range), pink noise 500 Hz–2 kHz (the standard calibration band), white noise,
  and a sine tone. All are RMS-normalized, so the level slider reads dBFS RMS. Each channel gets its own
  uncorrelated noise, with click-free fades.
- **Subwoofer (LFE):** an optional low-pass on the LFE test signal, with an adjustable cutoff (30–200 Hz, default 80 Hz).
- **Per-speaker level knobs** set the Windows per-channel volume (the same values as Sound settings → Levels → Balance).
  These settings are system-wide and stay set after a restart. Windows keeps the master volume equal to the loudest
  channel, so a balance set here survives later volume changes.
- **Microphone leveling:**
  - Live mic meter.
  - **Set reference**: while one speaker plays, lock its mic level. Every speaker tile then shows its mic level and
    its difference (Δ) from the reference, updated live while it plays (1.5 s average). Turn the speaker's knob
    until it reads Δ 0.0; a check mark appears within ±0.5 dB.
  - **Auto-level**: measures each selected speaker and sets the channel volumes to match the reference, or the
    quietest speaker if no reference is set, over up to three measure/adjust passes. It checks the background-noise
    margin, mic clipping, and whether the device actually applies the channel volume.
- **Auto-cycle** steps through the selected speakers one at a time.
- **Shortcuts:** Space plays and stops; keys 1–9 or right-click solo a speaker.
- **Dark** (default), Light, or System theme.
- **Auto-update** from GitHub Releases.

> Virtual mixers such as Voicemeeter ignore Windows channel volume, so the knobs have no effect on them. MCAL shows a
> warning when one is selected; level on the physical output device instead.

## Build

Requires the .NET 8 SDK and Inno Setup 6.

```powershell
.\build.ps1              # -> artifacts\MCAL-Setup-<version>.exe
```

## Releasing

1. Bump `<Version>` in `src/MCAL/MCAL.csproj` and commit.
2. Tag the commit and push the tag:
   ```powershell
   git tag v0.5.0
   git push origin v0.5.0
   ```
3. The `Release` workflow builds `MCAL-Setup-<version>.exe` and publishes it as a GitHub Release.

## How auto-update works

- On startup (unless `AutoCheckUpdates` is `false` in settings) and when you click **Check for updates**, the app
  reads `releases/latest` from the GitHub API and compares the tag to its own version.
- If a newer release exists, a banner offers **Install update**. The app then:
  1. Downloads the `MCAL-Setup-*.exe` asset to `%TEMP%\MCAL-Update`.
  2. Checks the download against the SHA-256 digest GitHub publishes for the asset.
  3. Runs the installer with `/SILENT`. Windows asks for admin approval.
  4. Exits.
- The installer upgrades `C:\Program Files\MCAL` in place (fixed `AppId`) and relaunches MCAL as the signed-in user.

## Layout

```
src/MCAL/
  Audio/        DeviceService (WASAPI enumeration + change notifications)
                SpeakerLayout (channel mask -> named/positioned speakers)
                TestSignalProvider (signal generation in the device mix format)
                ChannelVolume (Windows per-channel endpoint volume, channel mapping)
                MicMeter (mic capture, band-filtered level measurement), Biquad
  Controls/     TrimKnob (rotary level knob)
  Updates/      UpdateService (GitHub Releases check, download, install)
  Theming/      ThemeManager (palette swap, system theme tracking, dark title bar)
  Themes/       Dark.xaml / Light.xaml palettes, Controls.xaml styles
installer/      Inno Setup script (Program Files\MCAL, fixed AppId, removes the old "Audio Level" install)
tools/          make-icon.ps1 (regenerates Assets/MCAL.ico)
.github/        CI build + tag-triggered release workflow
```

Settings are stored in `%APPDATA%\MCAL\settings.json`.
