# Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/crssi/Firefox/master/get-profile.ps1'))

if ($PSVersionTable.PSVersion.Major -le 4) { Exit }

do { Start-Sleep -Milliseconds 500 } while ((Get-Process -Name 'firefox' -ErrorAction SilentlyContinue | Stop-Process) -ne $null)
do { Start-Sleep -Milliseconds 500 } while ((Get-Process -Name 'proxsign' -ErrorAction SilentlyContinue | Stop-Process) -ne $null)

Remove-Item -Path ($tmpFile = New-TemporaryFile)
$tmpFolder = New-Item -Path $tmpFile.DirectoryName -Name $tmpFile.Name -ItemType 'directory'
Remove-Variable -Name tmpFile

Import-Module -Name BitsTransfer
try { Start-BitsTransfer -Source https://github.com/crssi/Firefox/raw/master/Profile.zip -Destination $tmpFolder -ErrorAction Stop } catch { Exit }

$timestamp = (Get-Date).ToString('yyyy.MM.dd_HH.mm.ss')
try { Compress-Archive -Path "$($env:APPDATA)\Mozilla\Firefox\*" -DestinationPath "$($env:APPDATA)\Mozilla\Firefox_Profile_Backup-$timestamp.zip" -CompressionLevel Fastest } catch { Remove-Item -Path $tmpFolder -Recurse -Force -Confirm:$false; Exit }

Expand-Archive -Path "$tmpFolder\profile.zip" -DestinationPath $tmpFolder
Remove-Item -Path "$tmpFolder\profile.zip" -Force

Get-Content -Path "$tmpFolder\installs.ini" | ForEach-Object { if ($_.StartsWith('Default=Profiles/')) { $newProfilePath = "$($env:APPDATA)\Mozilla\Firefox\Profiles\$($_.Replace('Default=Profiles/', ''))" } }
Get-Content -Path "$($env:APPDATA)\Mozilla\Firefox\installs.ini" | ForEach-Object { if ($_.StartsWith('Default=Profiles/')) { $oldProfilePath = "$($env:APPDATA)\Mozilla\Firefox\Profiles\$($_.Replace('Default=Profiles/', ''))" } }
$tmpProfilePath = "$tmpFolder\Profiles\$($newProfilePath.split('\')[-1])"

$userProfileFiles = @('cert9.db','content-prefs.sqlite','favicons.sqlite','handlers.json','key4.db','logins.json','permissions.sqlite','persdict.dat','pkcs11.txt','places.sqlite')
$userProfileFiles | ForEach-Object { Copy-Item -Path "$oldProfilePath\$_" -Destination "$tmpProfilePath\$_" -Force -ErrorAction SilentlyContinue }

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
$files = @('extensions.json','compatibility.ini','pluginreg.dat','addonStartup.json')
forEach ($file in $files) {
    $content = Get-Content -Encoding UTF8 -Path $tmpFolder\$file
    $content = $content.Replace('%appdata%/',"$($env:APPDATA.Replace('\','/').Replace(' ','%20'))/")
    $content = $content.Replace('%appdata%\\',"$($env:APPDATA.Replace('\','\\'))\\")
    $content = $content.Replace('%programfiles%/',"$($env:ProgramFiles.Replace('\','/').Replace(' ','%20'))/")
    $content = $content.Replace('%programfiles%\\',"$($env:ProgramFiles.Replace('\','\\'))\\")
    $content = $content.Replace('%programfiles%\',"$($env:ProgramFiles)\")
    [System.IO.File]::WriteAllLines("$tmpFolder\$file", $content, $Utf8NoBomEncoding)
}

& "$tmpFolder\jsonlz4.exe" @("$tmpFolder\addonStartup.json","$tmpFolder\addonStartup.json.lz4")
Remove-Item -Path "$tmpFolder\addonStartup.json" -Force
Remove-Item -Path "$tmpFolder\jsonlz4.exe" -Force

Remove-Item -Path "$($env:APPDATA)\Mozilla\Firefox" -Recurse -Force -Confirm:$false
Move-Item -Path "$tmpFolder" -Destination "$($env:APPDATA)\Mozilla\Firefox" -Force

Remove-Variable -Name tmpFolder,oldProfilePath,newProfilePath,tmpProfilePath,Utf8NoBomEncoding,files,file,content



Start-Process -FilePath 'firefox.exe'

Exit



Start-Process -FilePath 'firefox.exe' -ArgumentList 'about:addons'
$firefoxApp = New-Object -ComObject wscript.shell
do { Start-Sleep -Milliseconds 500 } while ($firefoxApp.AppActivate('Firefox') -eq $false)
Start-Sleep -Milliseconds 3000
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Windows.Forms.Messagebox]::Show("IMPORTANT: Enable all addons !","User action required !")

Exit