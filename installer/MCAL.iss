; Inno Setup script for MCAL - Multi Channel Audio Leveler.
; Built by build.ps1 (locally and by the GitHub release workflow), which passes AppVersion and PublishDir.
; The in-app updater downloads this installer from GitHub Releases and runs it with /SILENT.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef PublishDir
  #define PublishDir "..\artifacts\publish"
#endif

#define AppName "Multi Channel Audio Leveler"
#define AppShortName "MCAL"
#define AppExe "MCAL.exe"
#define RepoUrl "https://github.com/rosscarlson/MCAL"
; AppId of the earlier per-user "Audio Level" builds (0.1-0.3), removed on install.
#define LegacyAppId "{8C4E2A71-3B5D-4F2E-9A61-7D0C5B1E9F42}"

[Setup]
; Never change AppId - upgrades and the auto-updater rely on it.
AppId={{5B7E9C2D-41A8-4F63-9E0B-2C8D6A1F7E35}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=rosscarlson
AppPublisherURL={#RepoUrl}
AppSupportURL={#RepoUrl}/issues
AppUpdatesURL={#RepoUrl}/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\MCAL
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=admin
OutputBaseFilename=MCAL-Setup-{#AppVersion}
SetupIconFile=..\src\MCAL\Assets\MCAL.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; Interactive install: optional "Launch" checkbox on the last page.
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent runasoriginaluser
; Silent install (auto-update): relaunch the app as the signed-in user, not elevated.
Filename: "{app}\{#AppExe}"; Flags: nowait skipifnotsilent runasoriginaluser

[Code]
// Remove the earlier per-user "Audio Level" install, if present.
procedure RemoveLegacyInstall();
var
  Uninstaller: String;
  ResultCode: Integer;
begin
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#LegacyAppId}_is1',
    'UninstallString', Uninstaller) then
  begin
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM AudioLevel.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(RemoveQuotes(Uninstaller), '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    RemoveLegacyInstall();
end;
