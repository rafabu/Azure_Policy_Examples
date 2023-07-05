# unattended file download & installer
Param(
    [string]$webURL = "https://go.microsoft.com/fwlink/?linkid=2237021",
    [string]$installParams = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /MERGETASKS=!runcode",
    [int]$timeoutSeconds = 900
)

Function Get-FileLock {
    param(
        [string]$path
    )
    $IsLocked = $false
    If ([System.IO.File]::Exists($path)) {
        Try {
            $FileStream = [System.IO.File]::Open($path, 'Open', 'Write')
            $FileStream.Close()
            $FileStream.Dispose()
        }
        Catch [System.UnauthorizedAccessException] {
            $IsLocked = 'AccessDenied'
        }
        Catch {
            $IsLocked = $true
        }
    }
    return $IsLocked
}

$Tmp = New-TemporaryFile
$TmpName = ("{0}.exe" -f $tmp.Name)
$TmpFullName = ("{0}.exe" -f $tmp.FullName)
Rename-Item -Path $tmp.FullName -NewName $TmpName
Invoke-WebRequest -URI $webURL -OutFile $TmpFullName -TimeoutSec $timeoutSeconds
# Execute Installer in elevated comspec
$process = Start-Process -FilePath "$env:comspec" -ArgumentList ('/c "{0}" {1}' -f $TmpFullName, $installParams)  -Verb "RunAs" -WindowStyle "Minimized" -PassThru
$secPassed = 0
Do {
    Write-Output ("[Info] installer running with PID {0}" -f $process.Id)
    Start-Sleep -Seconds 10
    $secPassed = $secPassed + 10
}
While (1 -eq @(get-process -Id $process.Id -ErrorAction SilentlyContinue).length -and ($timeoutSeconds -gt $secPassed))
if (1 -eq @(get-process -Id $process.Id -ErrorAction SilentlyContinue).length) {
    Stop-Process -ID $process.Id -Force
    Write-Host ("[Warning] forcefully stopped installation process {0}" -f $process.Id)
}
Remove-Item -Path $TmpFullName -Force
Write-Host ("[Info] installed downloaded program and deleted temporary installation file {0}" -f $TmpFullName)
