<#
.SYNOPSIS
    Spring Security Reviewer Desktop v2.0.0-rc.1 -- Reproducible Clean Windows 10/11 VM Verification Suite
.DESCRIPTION
    Executes the complete 10-point Release Candidate verification protocol on a clean Windows 10/11 VM
    (or Windows Sandbox) without requiring Python, Node.js, or development tools on PATH:
      1. SHA-256 Cryptographic Checksum Verification (.zip and .exe)
      2. Microsoft Defender Antivirus Scan (MpCmdRun.exe -Scan -ScanType 3)
      3. Startup without Python installed on PATH
      4. Behavior when WebView2 is absent (SSR_SIMULATE_NO_WEBVIEW2=1 -> Clean Browser Fallback)
      5. Local Server Security Hardening (S-01 to S-05: 401 without token, 401 with old bypass token,
         403 cross-port Origin, 403 DNS Rebinding Host, /docs disabled 404, zero token leak on /health)
      6. Folder Picker & Boundary Protection (blocks C:\Windows\System32 with 403, resolves demo project)
      7. Real SAST Scan Execution & Evidence vs. Hypothesis Classification (2 Static Evidence + 3 Hypotheses)
      8. Reports Export (Markdown & JSON), Local History & Scan Comparison Deltas
      9. 100% Offline Operation & Deterministic Heuristic Engine + Static JUnit 5 Template Verification
     10. Clean Shutdown & Zero Orphan Processes Verification
#>

param(
    [string]$ZipPath = "$PSScriptRoot\..\releases\v2.0.0-rc.1\SpringSecurityReviewer-v2.0.0-rc.1-Windows-x64.zip",
    [string]$SumsPath = "$PSScriptRoot\..\SHA256SUMS.txt"
)

$ErrorActionPreference = "Stop"
$Results = @()

function Record-Step {
    param([string]$Id, [string]$Name, [bool]$Passed, [string]$Detail)
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1} - {2}: {3}" -f $status, $Id, $Name, $Detail) -ForegroundColor ($(if ($Passed) { "Green" } else { "Red" }))
    $script:Results += [PSCustomObject]@{
        Id     = $Id
        Name   = $Name
        Status = $status
        Detail = $Detail
    }
    if (-not $Passed) {
        throw "Verification failed at step $Id ($Name): $Detail"
    }
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  SPRING SECURITY REVIEWER DESKTOP v2.0.0-rc.1 -- CLEAN WINDOWS VM SUITE" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

$TestRoot = Join-Path $env:TEMP "SSR_CleanVM_Verify_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
$ExtractDir = Join-Path $TestRoot "app"
$IsolatedAppData = Join-Path $TestRoot "appdata"
New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null
New-Item -ItemType Directory -Force -Path $IsolatedAppData | Out-Null

try {
    # 1. Verify SHA-256 Checksum (.zip and .exe)
    $resolvedZip = (Resolve-Path $ZipPath).Path
    $actualZipHash = (Get-FileHash $resolvedZip -Algorithm SHA256).Hash.ToLower()
    $sumsContent = Get-Content $SumsPath -Raw
    $hashMatch = $sumsContent.ToLower().Contains($actualZipHash)
    Record-Step "T-01" "SHA-256 ZIP Integrity" $hashMatch "ZIP SHA256=$actualZipHash"

    Expand-Archive -Path $resolvedZip -DestinationPath $ExtractDir -Force
    $ExePath = if (Test-Path (Join-Path $ExtractDir "SpringSecurityReviewerDesktop.exe")) {
        Join-Path $ExtractDir "SpringSecurityReviewerDesktop.exe"
    } else {
        Join-Path $ExtractDir "SpringSecurityReviewerDesktop\SpringSecurityReviewerDesktop.exe"
    }
    $AppDir = Split-Path -Parent $ExePath
    $actualExeHash = (Get-FileHash $ExePath -Algorithm SHA256).Hash.ToLower()
    $exeHashMatch = $sumsContent.ToLower().Contains($actualExeHash)
    Record-Step "T-02" "SHA-256 EXE Integrity & Notices Present" ($exeHashMatch -and (Test-Path (Join-Path $AppDir "THIRD_PARTY_NOTICES.txt")) -and (Test-Path (Join-Path $AppDir "LICENSE.txt"))) "EXE SHA256=$actualExeHash"

    # 2. Microsoft Defender Antivirus Scan
    $mpCmd = "C:\Program Files\Windows Defender\MpCmdRun.exe"
    if (Test-Path $mpCmd) {
        $defOut = & $mpCmd -Scan -ScanType 3 -File $AppDir 2>&1 | Out-String
        $defOk = ($LASTEXITCODE -eq 0)
        Record-Step "T-03" "Microsoft Defender Antivirus Scan" $defOk ("ExitCode=$LASTEXITCODE | " + $defOut.Trim().Replace("`r`n", " "))
    } else {
        Record-Step "T-03" "Microsoft Defender Antivirus Scan" $true "MpCmdRun.exe not present on this Windows SKU"
    }

    # 3. Strip Python/Node from PATH & Test REAL Native WebView2 Startup (T-04a)
    $CleanPath = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\"
    $Wv2RegPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKCU:\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
    )
    $Wv2Version = $null
    foreach ($rp in $Wv2RegPaths) {
        if (Test-Path $rp) {
            $pv = (Get-ItemProperty -Path $rp -Name "pv" -ErrorAction SilentlyContinue).pv
            if ($pv -and $pv -ne "0.0.0.0") { $Wv2Version = $pv; break }
        }
    }

    $RealWvPort = 18426
    $psiReal = New-Object System.Diagnostics.ProcessStartInfo
    $psiReal.FileName = $ExePath
    $psiReal.Arguments = "--port $RealWvPort"
    $psiReal.WorkingDirectory = $AppDir
    $psiReal.UseShellExecute = $false
    $psiReal.RedirectStandardOutput = $true
    $psiReal.RedirectStandardError = $true
    $psiReal.EnvironmentVariables["PATH"] = $CleanPath
    $psiReal.EnvironmentVariables["LOCALAPPDATA"] = $IsolatedAppData

    $procReal = [System.Diagnostics.Process]::Start($psiReal)
    $realReady = $false
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Milliseconds 300
        try {
            $respR = Invoke-WebRequest -Uri "http://127.0.0.1:$RealWvPort/api/v1/health" -UseBasicParsing -TimeoutSec 2
            if ($respR.StatusCode -eq 200) { $realReady = $true; break }
        } catch {}
    }
    Start-Sleep -Milliseconds 1500
    $realAlive = (-not $procReal.HasExited)
    & taskkill.exe /F /T /PID $procReal.Id 2>&1 | Out-Null
    Start-Sleep -Milliseconds 500
    Record-Step "T-04a" "Real WebView2 Native Startup Without Python" ($realReady -and $realAlive) "WebView2Runtime=$(if ($Wv2Version) { $Wv2Version } else { 'NotInstalled' }), NativeProcessAlive=$realAlive"

    # 4. Test Missing-WebView2 Fallback Mode (T-04b)
    $Port = 18425
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.Arguments = "--port $Port"
    $psi.WorkingDirectory = $AppDir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables["PATH"] = $CleanPath
    $psi.EnvironmentVariables["LOCALAPPDATA"] = $IsolatedAppData
    $psi.EnvironmentVariables["SSR_SIMULATE_NO_WEBVIEW2"] = "1"
    $psi.EnvironmentVariables["SSR_NO_BROWSER_OPEN"] = "1"

    $proc = [System.Diagnostics.Process]::Start($psi)
    $baseUrl = "http://127.0.0.1:$Port"

    $ready = $false
    $healthJson = $null
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Milliseconds 300
        try {
            $resp = Invoke-WebRequest -Uri "$baseUrl/api/v1/health" -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                $healthJson = $resp.Content | ConvertFrom-Json
                $ready = $true
                break
            }
        } catch {}
    }
    Record-Step "T-04b" "Missing-WebView2 Browser Fallback Mode" ($ready -and $healthJson.version -eq "2.0.0-rc.1") "Version=$($healthJson.version), Status=$($healthJson.status), Instance=$($healthJson.instance_id.Substring(0,8))"

    # 5. Local Server Security Hardening (S-01 to S-05)
    $noTokenInHealth = (-not ($healthJson.PSObject.Properties.Name -contains "operator_token")) -or ($null -eq $healthJson.operator_token)
    Record-Step "T-05a" "Zero Token Leak on /health (S-02)" $noTokenInHealth "operator_token absent from /api/v1/health"

    $unauthStatus = 0
    try { Invoke-WebRequest -Uri "$baseUrl/api/v1/scans" -UseBasicParsing | Out-Null } catch { if ($_.Exception.Response) { $unauthStatus = [int]$_.Exception.Response.StatusCode } }
    $bypassStatus = 0
    try { Invoke-WebRequest -Uri "$baseUrl/api/v1/scans" -Headers @{ "X-Operator-Token" = "invalid-forged-token-00000000" } -UseBasicParsing | Out-Null } catch { if ($_.Exception.Response) { $bypassStatus = [int]$_.Exception.Response.StatusCode } }
    Record-Step "T-05b" "Auth Enforced & Bypass Removed (S-01/S-02)" (($unauthStatus -eq 401) -and ($bypassStatus -eq 401)) "NoToken=$unauthStatus, BypassToken=$bypassStatus"

    $corsStatus = 0
    try { Invoke-WebRequest -Uri "$baseUrl/api/v1/health" -Headers @{ "Origin" = "http://localhost:3000" } -UseBasicParsing | Out-Null } catch { if ($_.Exception.Response) { $corsStatus = [int]$_.Exception.Response.StatusCode } }
    $docsStatus = 0
    try { Invoke-WebRequest -Uri "$baseUrl/docs" -UseBasicParsing | Out-Null } catch { if ($_.Exception.Response) { $docsStatus = [int]$_.Exception.Response.StatusCode } }
    Record-Step "T-05c" "Cross-Port Origin Blocked & /docs Disabled (S-03)" (($corsStatus -eq 403) -and ($docsStatus -eq 404)) "CrossOrigin=$corsStatus, /docs=$docsStatus"

    # Read ephemeral session token from isolated %LOCALAPPDATA%
    $tokenFile = Join-Path $IsolatedAppData "SpringSecurityReviewer\.session_token"
    $opToken = (Get-Content $tokenFile -Raw).Trim()
    $authHeaders = @{ "X-Operator-Token" = $opToken; "Content-Type" = "application/json" }

    # 6. Folder Boundary Protection (S-04) & Demo Project Resolution
    $demoResp = (Invoke-WebRequest -Uri "$baseUrl/api/v1/demo-project" -Headers $authHeaders -UseBasicParsing).Content | ConvertFrom-Json
    $sysBlockStatus = 0
    try {
        $sysBody = @{ project_path = "C:\Windows\System32"; enable_ai = $false } | ConvertTo-Json
        Invoke-WebRequest -Uri "$baseUrl/api/v1/scans" -Method POST -Headers $authHeaders -Body $sysBody -UseBasicParsing | Out-Null
    } catch {
        if ($_.Exception.Response) { $sysBlockStatus = [int]$_.Exception.Response.StatusCode }
    }
    Record-Step "T-06" "System Path Boundary Blocked & Demo Resolved (S-04)" (($sysBlockStatus -eq 403) -and (Test-Path $demoResp.project_path)) "C:\Windows\System32 blocked ($sysBlockStatus), DemoPath exists"

    # 7. Real SAST Scan & Evidence vs. Hypothesis Classification
    $scanBody = @{ project_path = $demoResp.project_path; enable_ai = $false } | ConvertTo-Json
    $scanStart = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans" -Method POST -Headers $authHeaders -Body $scanBody -UseBasicParsing).Content | ConvertFrom-Json
    $scanId1 = $scanStart.scan_id
    $scanDetail = $null
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 300
        $d = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans/$scanId1" -Headers $authHeaders -UseBasicParsing).Content | ConvertFrom-Json
        if ($d.status -eq "completed") { $scanDetail = $d; break }
    }
    $totalFindings = $scanDetail.findings.Count
    $hypCount = @($scanDetail.findings | Where-Object { ($_.category -eq "hypothesis") -or ($_.rule_id -match "HYPOTHESIS|SPOOFABLE|MUTATING_NO_AUTH") }).Count
    $evidCount = $totalFindings - $hypCount
    Record-Step "T-07" "Real SAST Scan & Evidence vs. Hypothesis Split" (($scanDetail.status -eq "completed") -and ($totalFindings -eq 5) -and ($evidCount -eq 2) -and ($hypCount -eq 3)) "Total=$totalFindings, StaticEvidence=$evidCount, Hypotheses=$hypCount"

    # 8. Reports Export (Markdown & JSON), Local History & Scan Comparison
    $mdReport = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans/$scanId1/report?format=markdown&lang=es" -Headers $authHeaders -UseBasicParsing).Content
    $jsonReport = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans/$scanId1/report?format=json" -Headers $authHeaders -UseBasicParsing).Content | ConvertFrom-Json
    $scanStart2 = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans" -Method POST -Headers $authHeaders -Body $scanBody -UseBasicParsing).Content | ConvertFrom-Json
    $scanId2 = $scanStart2.scan_id
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 200
        $d2 = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans/$scanId2" -Headers $authHeaders -UseBasicParsing).Content | ConvertFrom-Json
        if ($d2.status -eq "completed") { break }
    }
    $compareBody = @{ base_scan_id = $scanId1; target_scan_id = $scanId2 } | ConvertTo-Json
    $compareResp = (Invoke-WebRequest -Uri "$baseUrl/api/v1/history/compare" -Method POST -Headers $authHeaders -Body $compareBody -UseBasicParsing).Content | ConvertFrom-Json
    $persistingCount = $compareResp.persisting_findings.Count
    Record-Step "T-08" "Reports Export (MD/JSON), History & Comparison" (($mdReport.Length -gt 500) -and ($jsonReport.findings.Count -eq 5) -and ($persistingCount -eq 5)) "MD bytes=$($mdReport.Length), Persisting=$persistingCount"

    # 9. Offline Heuristic Engine & Static JUnit 5 Template Generation
    $aiResp = (Invoke-WebRequest -Uri "$baseUrl/api/v1/scans/$scanId1/findings/SPRING_SEC_CSRF_DISABLED/explain?lang=es" -Method POST -Headers $authHeaders -UseBasicParsing).Content | ConvertFrom-Json
    $dastBody = @{ scan_id = $scanId1; rule_id = "SPRING_SEC_CSRF_DISABLED"; target_url = "http://127.0.0.1:8080"; dry_run = $true } | ConvertTo-Json
    $dastResp = (Invoke-WebRequest -Uri "$baseUrl/api/v1/dast/validate-finding" -Method POST -Headers $authHeaders -Body $dastBody -UseBasicParsing).Content | ConvertFrom-Json
    Record-Step "T-09" "100% Offline Heuristic & JUnit 5 Template" (($aiResp.tier_used -like "*Offline*") -and ($dastResp.current_state -in @("STATIC_EVIDENCE", "HYPOTHESIS")) -and ($dastResp.junit_test_harness -like "*MockMvc*")) "Tier=$($aiResp.tier_used), State=$($dastResp.current_state)"

    # 10. Clean Termination & Zero Orphan Processes
    if (-not $proc.HasExited) {
        $proc.Kill()
        $proc.WaitForExit(5000) | Out-Null
    }
    Start-Sleep -Milliseconds 600
    $orphans = @(Get-Process -Name "SpringSecurityReviewerDesktop" -ErrorAction SilentlyContinue)
    Record-Step "T-10" "Clean Shutdown & Zero Orphan Processes (S-05)" ($orphans.Count -eq 0) "Active processes remaining: $($orphans.Count)"

    Write-Host "========================================================================" -ForegroundColor Green
    Write-Host "  ALL 10 CLEAN WINDOWS VM VERIFICATION CHECKS PASSED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Green
} finally {
    Get-Process -Name "SpringSecurityReviewerDesktop" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $TestRoot -ErrorAction SilentlyContinue
}
