param(
    [Parameter(Mandatory = $true)][string] $SourceDir,
    [Parameter(Mandatory = $true)][string] $InstallerPath,
    [string] $IsccPath
)
$ErrorActionPreference = 'Stop'
$metadata = Get-Content -Raw (Join-Path $PSScriptRoot 'windows.json') | ConvertFrom-Json
$sourceRoot = (Resolve-Path -LiteralPath $SourceDir).Path
$installerFullPath = [IO.Path]::GetFullPath($InstallerPath)
if (Test-Path -LiteralPath $installerFullPath) { throw "Output already exists: $installerFullPath" }
$installerDir = Split-Path -Parent $installerFullPath
$outputBaseFilename = [IO.Path]::GetFileNameWithoutExtension($installerFullPath)
New-Item -ItemType Directory -Force -Path $installerDir | Out-Null
$iconPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../mobile/apps/auth/assets/icons/auth-icon.ico'))
$issPath = Join-Path $installerDir "$outputBaseFilename.iss"
if (Test-Path -LiteralPath $issPath) { throw "Installer source already exists: $issPath" }
$iss = @"
[Setup]
AppId=$($metadata.installerAppId)
AppVersion=$($metadata.version)
AppName=$($metadata.name)
AppPublisher=$($metadata.publisher)
AppPublisherURL=$($metadata.repository)
AppSupportURL=$($metadata.repository)/issues
AppUpdatesURL=$($metadata.repository)/releases
DefaultDirName={localappdata}\Programs\ProtEnte
DisableProgramGroupPage=yes
OutputDir=$installerDir
OutputBaseFilename=$outputBaseFilename
Compression=lzma2
SolidCompression=yes
SetupIconFile=$iconPath
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\protente.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$sourceRoot\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
Root: HKCU; Subkey: "Software\Classes\protente"; ValueType: string; ValueData: "URL:ProtEnte"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\protente"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\protente\shell\open\command"; ValueType: string; ValueData: """{app}\protente.exe"" ""%1"""

[Icons]
Name: "{autoprograms}\ProtEnte"; Filename: "{app}\protente.exe"
Name: "{autodesktop}\ProtEnte"; Filename: "{app}\protente.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\protente.exe"; Description: "{cm:LaunchProgram,ProtEnte}"; Flags: nowait postinstall skipifsilent
"@
[IO.File]::WriteAllText($issPath, $iss, [Text.UTF8Encoding]::new($true))
if (-not $IsccPath) {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) { $IsccPath = $command.Source }
    else { $IsccPath = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' }
}
if (-not (Test-Path -LiteralPath $IsccPath -PathType Leaf)) { throw 'Inno Setup 6 is required.' }
& $IsccPath $issPath
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed: $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $installerFullPath -PathType Leaf)) { throw 'Installer missing.' }
Write-Host "Created unsigned ProtEnte installer: $installerFullPath"
