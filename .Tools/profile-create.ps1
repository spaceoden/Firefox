# https://github.com/avih/dejsonlz4
Get-Content -Path "$($env:APPDATA)\Mozilla\Firefox\installs.ini" | ForEach-Object { if ($_.StartsWith('Default=Profiles/')) { $profilePath = "$($env:APPDATA)\Mozilla\Firefox\Profiles\$($_.Replace('Default=Profiles/', ''))" } }
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

& "$env:UserProfile\Documents\GitHub\Firefox\.Tools\dejsonlz4.exe" @("$profilePath\addonStartup.json.lz4","$profilePath\addonStartup.json")
Copy-Item "$env:UserProfile\Documents\GitHub\Firefox\.Tools\jsonlz4.exe" $profilePath -Force

$files = @('extensions.json','pkcs11.txt','compatibility.ini','pluginreg.dat','addonStartup.json')
forEach ($file in $files) {
    $content = Get-Content -Encoding UTF8 -Path $profilePath\$file
    $content = $content.Replace($env:APPDATA.Replace('\','/').Replace(' ','%20'),'%appdata%')
    $content = $content.Replace($env:APPDATA.Replace('\','\\'),'%appdata%')
    $content = $content.Replace($env:ProgramFiles.Replace('\','/').Replace(' ','%20'),'%programfiles%')
    $content = $content.Replace($env:ProgramFiles.Replace('\','\\'),'%programfiles%')
    $content = $content.Replace($env:ProgramFiles,'%programfiles%')
    [System.IO.File]::WriteAllLines("$profilePath\$file", $content, $Utf8NoBomEncoding)
}

Get-ChildItem $profilePath\storage\default | where { $_.name -notmatch '\^userContextId' } | Remove-Item -Recurse -Force -Confirm:$false
Get-ChildItem $profilePath\addonStartup.json.lz4 | Remove-Item -Force
Get-ChildItem $profilePath\pkcs11.txt | Remove-Item -Force

Compress-Archive -Path "$($env:APPDATA)\Mozilla\Firefox\*" -DestinationPath "$env:UserProfile\Documents\GitHub\Firefox\Profile.zip" -CompressionLevel Optimal -Force
