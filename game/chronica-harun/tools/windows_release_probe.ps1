param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = 'Stop'

$qaRoot = Join-Path $GameDir 'runtime-qa/windows-native'
$buildDir = Join-Path $GameDir 'build/windows'
$exe = Join-Path $buildDir 'CHRONICA_HARUN.exe'
$zip = Join-Path $buildDir 'CHRONICA_HARUN-Windows-x86_64.zip'
$hashFile = Join-Path $buildDir 'CHRONICA_HARUN.exe.sha256.txt'
$probeJson = Join-Path $qaRoot 'release-probe.json'
$screenshotPath = Join-Path $qaRoot 'windows-native-smoke.png'

New-Item -ItemType Directory -Force -Path $qaRoot | Out-Null
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if (-not (Test-Path $exe)) {
    throw "CHRONICA_HARUN.exe does not exist at $exe"
}

$bytes = [System.IO.File]::ReadAllBytes($exe)
if ($bytes.Length -lt 512) { throw 'EXE is too small to be a valid PE image' }

$dosSignature = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 2)
$peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
if ($peOffset -lt 0 -or ($peOffset + 26) -ge $bytes.Length) { throw 'PE header offset is outside the file' }

$peSignatureValid = (
    $bytes[$peOffset] -eq 0x50 -and
    $bytes[$peOffset + 1] -eq 0x45 -and
    $bytes[$peOffset + 2] -eq 0x00 -and
    $bytes[$peOffset + 3] -eq 0x00
)
$machine = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
$optionalMagic = [System.BitConverter]::ToUInt16($bytes, $peOffset + 24)

$mzValid = $dosSignature -eq 'MZ'
# AMD64 IMAGE_FILE_MACHINE_AMD64 = 0x8664
$amd64 = $machine -eq 0x8664
# PE32+ optional header magic = 0x20b
$pe32Plus = $optionalMagic -eq 0x20b
$peValid = $mzValid -and $peSignatureValid -and $amd64 -and $pe32Plus

$versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
$versionMetadataPass = (
    $versionInfo.ProductName -eq 'CHRONICA HARUN' -and
    $versionInfo.FileDescription -eq 'CHRONICA HARUN' -and
    -not [string]::IsNullOrWhiteSpace($versionInfo.FileVersion) -and
    -not [string]::IsNullOrWhiteSpace($versionInfo.ProductVersion)
)

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class ChronicaResourceProbe
{
    public delegate bool EnumResNameProc(IntPtr hModule, IntPtr lpszType, IntPtr lpszName, IntPtr lParam);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr LoadLibraryEx(string lpFileName, IntPtr hFile, uint dwFlags);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FreeLibrary(IntPtr hModule);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumResourceNames(IntPtr hModule, IntPtr lpszType, EnumResNameProc lpEnumFunc, IntPtr lParam);
}
"@

function Test-NativeResourceType {
    param([int]$TypeId)
    $LOAD_LIBRARY_AS_DATAFILE = 0x00000002
    $module = [ChronicaResourceProbe]::LoadLibraryEx($exe, [IntPtr]::Zero, $LOAD_LIBRARY_AS_DATAFILE)
    if ($module -eq [IntPtr]::Zero) { return $false }
    try {
        $script:resourceFound = $false
        $callback = [ChronicaResourceProbe+EnumResNameProc]{
            param($hModule, $lpszType, $lpszName, $lParam)
            $script:resourceFound = $true
            return $false
        }
        [void][ChronicaResourceProbe]::EnumResourceNames($module, [IntPtr]$TypeId, $callback, [IntPtr]::Zero)
        return [bool]$script:resourceFound
    }
    finally {
        [void][ChronicaResourceProbe]::FreeLibrary($module)
    }
}

# Win32 resource IDs: RT_ICON = 3, RT_GROUP_ICON = 14.
$RT_ICON = 3
$RT_GROUP_ICON = 14
$iconResource = Test-NativeResourceType -TypeId $RT_ICON
$groupIconResource = Test-NativeResourceType -TypeId $RT_GROUP_ICON
$iconPresent = $iconResource -and $groupIconResource

$launchPass = $false
$launchExitImmediate = $false
$launchExitCode = $null
$screenshotCaptured = $false
$launchSeconds = 0.0
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$process = $null
try {
    $process = Start-Process -FilePath $exe -WorkingDirectory $buildDir -PassThru
    Start-Sleep -Seconds 8
    $process.Refresh()
    if ($process.HasExited) {
        $launchExitImmediate = $true
        $launchExitCode = $process.ExitCode
    }
    else {
        $launchPass = $true
        try {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen
            if ($null -ne $screen -and $screen.Bounds.Width -gt 0 -and $screen.Bounds.Height -gt 0) {
                $bitmap = New-Object System.Drawing.Bitmap $screen.Bounds.Width, $screen.Bounds.Height
                $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                try {
                    $graphics.CopyFromScreen($screen.Bounds.Location, [System.Drawing.Point]::Empty, $screen.Bounds.Size)
                    $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
                }
                finally {
                    $graphics.Dispose()
                    $bitmap.Dispose()
                }
                if ((Test-Path $screenshotPath) -and (Get-Item $screenshotPath).Length -gt 10000) {
                    $screenshotCaptured = $true
                }
            }
        }
        catch {
            $screenshotCaptured = $false
        }
    }
}
catch {
    $launchPass = $false
    $launchExitImmediate = $true
    $launchExitCode = -1
}
finally {
    $stopwatch.Stop()
    $launchSeconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
    if ($null -ne $process) {
        try {
            $process.Refresh()
            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                $process.WaitForExit(5000) | Out-Null
            }
        }
        catch { }
        $process.Dispose()
    }
}

$sha = (Get-FileHash -Path $exe -Algorithm SHA256).Hash.ToLowerInvariant()
"$sha  CHRONICA_HARUN.exe" | Set-Content -Path $hashFile -Encoding ascii

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $exe -DestinationPath $zip -CompressionLevel Optimal

$extractDir = Join-Path $env:RUNNER_TEMP ("chronica-zip-check-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
$zipIntegrityPass = $false
try {
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force
    $extractedExe = Join-Path $extractDir 'CHRONICA_HARUN.exe'
    if (Test-Path $extractedExe) {
        $extractedSha = (Get-FileHash -Path $extractedExe -Algorithm SHA256).Hash.ToLowerInvariant()
        $zipIntegrityPass = $extractedSha -eq $sha
    }
}
finally {
    Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}

$probe = [ordered]@{
    exe_name = 'CHRONICA_HARUN.exe'
    exe_size_bytes = (Get-Item $exe).Length
    sha256 = $sha
    dos_signature = $dosSignature
    mz_valid = $mzValid
    pe_signature_valid = $peSignatureValid
    machine_hex = ('0x{0:x4}' -f $machine)
    optional_magic_hex = ('0x{0:x3}' -f $optionalMagic)
    amd64 = $amd64
    pe32_plus = $pe32Plus
    pe_valid = $peValid
    launch_pass = $launchPass
    launch_exit_immediate = $launchExitImmediate
    launch_exit_code = $launchExitCode
    launch_runtime_seconds = $launchSeconds
    file_version = $versionInfo.FileVersion
    product_version = $versionInfo.ProductVersion
    company_name = $versionInfo.CompanyName
    product_name = $versionInfo.ProductName
    file_description = $versionInfo.FileDescription
    version_metadata_pass = $versionMetadataPass
    icon_resource = $iconResource
    group_icon_resource = $groupIconResource
    icon_present = $iconPresent
    zip_name = 'CHRONICA_HARUN-Windows-x86_64.zip'
    zip_integrity_pass = $zipIntegrityPass
    screenshot_captured = $screenshotCaptured
    screenshot_path = if ($screenshotCaptured) { 'runtime-qa/windows-native/windows-native-smoke.png' } else { $null }
    visual_qa = 'NOT TESTABLE IN CI'
    visual_statement = 'VISUAL QA NOT VERIFIED'
}

$probe | ConvertTo-Json -Depth 6 | Set-Content -Path $probeJson -Encoding utf8
$probe | ConvertTo-Json -Depth 6

$hardPass = $peValid -and $launchPass -and $zipIntegrityPass -and $versionMetadataPass -and $iconPresent
if (-not $hardPass) {
    Write-Host 'WINDOWS_RELEASE_PROBE=FAIL'
    if (-not $iconPresent) { Write-Host 'WINDOWS_RELEASE_BLOCKER=ICON_METADATA_MISSING' }
    Write-Host 'NOT TESTABLE IN CI: final render quality, physical pointer lock, GPU/VFX quality, real fullscreen acceptance.'
    Write-Host 'VISUAL QA NOT VERIFIED'
    exit 1
}

Write-Host 'WINDOWS_RELEASE_PROBE=PASS'
Write-Host 'NOT TESTABLE IN CI: final render quality, physical pointer lock, GPU/VFX quality, real fullscreen acceptance.'
Write-Host 'VISUAL QA NOT VERIFIED'
exit 0
