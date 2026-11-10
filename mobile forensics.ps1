# ============================================================
# ANDROID MOBILE FORENSIC TRIAGE & LOGICAL ACQUISITION
# Tool       : Android Debug Bridge (ADB)
# Platform   : Windows PowerShell
# Purpose    : Authorized logical forensic acquisition
# ============================================================

$ErrorActionPreference = "Continue"

# ---------------- CONFIGURATION ----------------

$Serial = ""   # Optional: Enter device serial number
$BaseDir = "$PWD\Android_Forensic_Evidence"

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$EvidenceDir = "$BaseDir\Acquisition_$TimeStamp"

New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

# ADB device selection
$AdbPrefix = @()

if ($Serial -ne "") {
    $AdbPrefix = @("-s", $Serial)
}

# ---------------- ADB CHECK ----------------

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ADB is not installed or not in PATH." -ForegroundColor Red
    exit
}

Write-Host "`n[+] Checking connected devices..."

& adb @AdbPrefix devices -l

& adb @AdbPrefix get-state

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No accessible ADB device." -ForegroundColor Red
    exit
}

# ---------------- CAPTURE FUNCTION ----------------

function Capture-ADB {
    param (
        [string]$Name,
        [string[]]$Arguments
    )

    $OutputFile = Join-Path $EvidenceDir "$Name.txt"

    Write-Host "[+] Collecting: $Name" -ForegroundColor Cyan

    & adb @AdbPrefix @Arguments 2>&1 |
        Out-File -FilePath $OutputFile -Encoding utf8
}

# ============================================================
# 1. DEVICE INFORMATION
# ============================================================

Capture-ADB "device_model" @("shell", "getprop", "ro.product.model")

Capture-ADB "device_manufacturer" @("shell", "getprop", "ro.product.manufacturer")

Capture-ADB "android_version" @("shell", "getprop", "ro.build.version.release")

Capture-ADB "android_sdk" @("shell", "getprop", "ro.build.version.sdk")

Capture-ADB "device_properties" @("shell", "getprop")

# ============================================================
# 2. CONTACT ACQUISITION
# ============================================================

Capture-ADB "contacts" @(
    "shell", "content", "query",
    "--uri", "content://com.android.contacts/data",
    "--projection", "display_name:data1:mimetype"
)

# ============================================================
# 3. CALL LOG ACQUISITION
# ============================================================

Capture-ADB "call_logs" @(
    "shell", "content", "query",
    "--uri", "content://call_log/calls",
    "--projection", "date:number:type:duration"
)

# ============================================================
# 4. SMS ACQUISITION
# ============================================================

Capture-ADB "sms_inbox" @(
    "shell", "content", "query",
    "--uri", "content://sms/inbox",
    "--projection", "address:body:date:type"
)

Capture-ADB "sms_sent" @(
    "shell", "content", "query",
    "--uri", "content://sms/sent",
    "--projection", "address:body:date:type"
)

# ============================================================
# 5. ACCOUNT INFORMATION
# ============================================================

Capture-ADB "accounts" @("shell", "dumpsys", "account")

# ============================================================
# 6. WIFI INFORMATION
# ============================================================

Capture-ADB "wifi_information" @("shell", "dumpsys", "wifi")

# ============================================================
# 7. LOCATION INFORMATION
# ============================================================

Capture-ADB "location_information" @("shell", "dumpsys", "location")

# ============================================================
# 8. BATTERY INFORMATION
# ============================================================

Capture-ADB "battery_information" @("shell", "dumpsys", "battery")

# ============================================================
# 9. ANDROID USER INFORMATION
# ============================================================

Capture-ADB "android_users" @("shell", "pm", "list", "users")

# ============================================================
# 10. INSTALLED APPLICATIONS
# ============================================================

Capture-ADB "all_packages" @(
    "shell", "pm", "list", "packages"
)

Capture-ADB "third_party_apps" @(
    "shell", "pm", "list", "packages", "-3", "-i"
)

# Apps not installed by Google Play Store
Capture-ADB "non_playstore_installer_apps" @(
    "shell", "pm", "list", "packages", "-3", "-i"
)

# ============================================================
# 11. WHATSAPP INFORMATION
# ============================================================

Capture-ADB "whatsapp_package" @(
    "shell", "pm", "path", "com.whatsapp"
)

# ============================================================
# 12. STORAGE INFORMATION
# ============================================================

Capture-ADB "storage_information" @(
    "shell", "df", "-h"
)

# ============================================================
# 13. MEDIA ACQUISITION
# ============================================================

Write-Host "`n[+] Pulling accessible shared storage..." -ForegroundColor Cyan

$MediaDir = Join-Path $EvidenceDir "Phone_Storage"

New-Item -ItemType Directory -Path $MediaDir -Force | Out-Null

& adb @AdbPrefix pull "/storage/emulated/0" $MediaDir

# ============================================================
# 14. ACQUISITION METADATA
# ============================================================

$Metadata = @"
Android Mobile Forensic Acquisition

Acquisition Date : $(Get-Date)
Computer Name    : $env:COMPUTERNAME
Operator         : $env:USERNAME
ADB Version      : $(& adb version | Select-Object -First 1)
Device Serial    : $Serial
Acquisition Type : Logical Acquisition
Evidence Folder  : $EvidenceDir
"@

$Metadata | Out-File "$EvidenceDir\Acquisition_Metadata.txt" -Encoding utf8

# ============================================================
# 15. SHA256 HASH GENERATION
# ============================================================

Write-Host "`n[+] Generating SHA256 hashes..." -ForegroundColor Cyan

$HashFile = Join-Path $EvidenceDir "SHA256_Manifest.csv"

Get-ChildItem $EvidenceDir -File -Recurse |
    Where-Object { $_.FullName -ne $HashFile } |
    ForEach-Object {
        $Hash = Get-FileHash $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            FileName = $_.FullName
            Algorithm = "SHA256"
            Hash = $Hash.Hash
        }
    } |
    Export-Csv $HashFile -NoTypeInformation -Encoding UTF8

# ============================================================
# COMPLETION
# ============================================================

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "   ACQUISITION COMPLETED" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "Evidence Location: $EvidenceDir"
Write-Host "SHA256 Manifest  : $HashFile"