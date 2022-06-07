# Download the latest Adobe Acrobat Reader DC x64
# https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get the link to the latest Adobe Acrobat Reader DC x64 installer
$TwoLetterISOLanguageName = (Get-WinSystemLocale).TwoLetterISOLanguageName
$Parameters = @{
	Uri = "https://rdc.adobe.io/reader/products?lang=$($TwoLetterISOLanguageName)&site=enterprise&os=Windows 11&api_key=dc-get-adobereader-cdn"
	UseBasicParsing = $true
}
$Version = (Invoke-RestMethod @Parameters).products.reader.version.Replace(".", "")
$LanguageCode = (Get-WinSystemLocale).Name.Replace("-", "_")

# Download the installer
$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
$Parameters = @{
    Uri             = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$($Version)/AcroRdrDCx64$($Version)_$($LanguageCode).exe"
    OutFile         = "$DownloadsFolder\AcroRdrDCx64$($Version)_$($LanguageCode).exe"
    UseBasicParsing = $true
}
Invoke-RestMethod @Parameters

# Extract to the "AcroRdrDCx64" folder
$Arguments = @(
	# Specifies the name of folder where the expanded package is placed
	"-sfx_o{0}" -f "$DownloadsFolder\AcroRdrDCx64"
	# Do not execute any file after installation (overrides the '-e' switch)
	"-sfx_ne"
)
Start-Process -FilePath "$DownloadsFolder\AcroRdrDCx64$($Version)_$($LanguageCode).exe" -ArgumentList $Arguments -Wait

# Extract AcroPro.msi to the "AcroPro.msi extracted" folder
$Arguments = @(
	"/a `"$DownloadsFolder\AcroRdrDCx64\AcroPro.msi`""
	"TARGETDIR=`"$DownloadsFolder\AcroRdrDCx64\AcroPro.msi extracted`""
	"/qb"
)
Start-Process "msiexec" -ArgumentList $Arguments -Wait

$Items = @(
	"$DownloadsFolder\AcroRdrDCx64\Core.cab",
	"$DownloadsFolder\AcroRdrDCx64\Languages.cab",
	"$DownloadsFolder\AcroRdrDCx64\WindowsInstaller-KB893803-v2-x86.exe",
	"$DownloadsFolder\AcroRdrDCx64\VCRT_x64"
)
Remove-Item -Path $Items -Recurse -Force -ErrorAction Ignore
Get-ChildItem -Path "$DownloadsFolder\AcroRdrDCx64\AcroPro.msi extracted" -Recurse -Force | Move-Item -Destination "$DownloadsFolder\AcroRdrDCx64" -Force
Remove-Item -Path "$DownloadsFolder\AcroRdrDCx64\AcroPro.msi extracted" -Force

# Create the edited setup.ini
$PatchFile = Split-Path -Path "$DownloadsFolder\AcroRdrDCx64\AcroRdrDCx64Upd$Version.msp" -Leaf

# setup.ini
# https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/properties.html
$CmdLine = @(
	"ENABLE_CHROMEEXT=0",
	"DISABLE_BROWSER_INTEGRATION=YES",
	"DISABLE_DISTILLER=YES",
	"REMOVE_PREVIOUS=YES",
	"IGNOREVCRT64=1",
	"EULA_ACCEPT=YES",
	"DISABLE_PDFMAKER=YES",
	"DISABLEDESKTOPSHORTCUT=2",
	# Install updates automatically
	"UPDATE_MODE=3"
)

$setupini = @"
[Product]
msi=AcroPro.msi
PATCH=$PatchFile
CmdLine=$CmdLine
"@
Set-Content -Path "$DownloadsFolder\AcroRdrDCx64\setup.ini" -Value $setupini -Encoding Default -Force
