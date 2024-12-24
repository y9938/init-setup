# Get the script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-ColoredStatus {
    param(
        [string]$Message,
        [string]$Status,
        [string]$Color = "White"
    )

    # Map status to appropriate colors
    $statusColor = switch ($Status) {
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "INFO"    { "Cyan" }
        "DONE"    { "Green" }
        default   { $Color }
    }

    Write-Host "[$Status] " -NoNewline -ForegroundColor $statusColor
    Write-Host $Message
}

function New-DirectoryIfNotExists {
    param(
        [string]$Path
    )
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-ColoredStatus "Created directory: $Path" "SUCCESS"
    }
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    if (Test-Path -Path $Source) {
        if (!(Test-Path -Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force
        Write-ColoredStatus "$Description copied successfully" "SUCCESS"
    }
    else {
        Write-ColoredStatus "$Source directory does not exist" "WARNING"
    }
}

function Set-KeyboardConfig {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0
        Write-ColoredStatus "Keyboard delay set to short" "SUCCESS"
        Write-ColoredStatus "Keyboard settings updated. A system restart is required to apply changes." "INFO"
    }
    catch {
        Write-ColoredStatus "Failed to update keyboard settings: $_" "ERROR"
    }
}

function Set-GitConfig {
    param(
        [switch]$Skip
    )

    if ($Skip) {
        Write-ColoredStatus "Skipping Git configuration" "INFO"
        return
    }

    if (!(Test-Path -Path "$HOME\.gitconfig")) {
        Write-Host "Do you want to configure Git? (y/N) " -ForegroundColor Cyan -NoNewline
        $confirmGit = Read-Host

        if ($confirmGit.ToLower() -ne 'y') {
            Write-ColoredStatus "Skipping Git configuration" "INFO"
            return
        }

        Write-Host "Enter your Git username: " -ForegroundColor Cyan -NoNewline
        $gitUsername = Read-Host

        Write-Host "Enter your Git email: " -ForegroundColor Cyan -NoNewline
        $gitEmail = Read-Host

        $templatePath = Join-Path $SCRIPT_DIR "config\git\.gitconfig-template"
        $gitConfig = Get-Content $templatePath
        $gitConfig = $gitConfig.Replace('{USERNAME}', $gitUsername)
        $gitConfig = $gitConfig.Replace('{EMAIL}', $gitEmail)
        $gitConfig | Set-Content "$HOME\.gitconfig"

        Write-ColoredStatus "Git configuration created" "SUCCESS"
    } else {
        Write-ColoredStatus "Git configuration already exists" "INFO"
    }
}

if ($env:OS -eq "Windows_NT") {
    Write-ColoredStatus "Starting Windows configuration..." "INFO"

    # Create standard directories
    $directories = @(
        "$HOME\.soft",
        "$HOME\library",
        "$HOME\scripts"
    )

    foreach ($dir in $directories) {
        New-DirectoryIfNotExists -Path $dir
    }

    # Copy desktop resources
    Copy-DirectoryContents -Source "$SCRIPT_DIR\resources\desktop" `
                         -Destination "$HOME\Desktop" `
                         -Description "Desktop resources"

    # Copy scripts
    Copy-DirectoryContents -Source "$SCRIPT_DIR\scripts\windows" `
                         -Destination "$HOME\scripts" `
                         -Description "Scripts"

    # Copy startup items
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    Copy-DirectoryContents -Source "$SCRIPT_DIR\resources\startup" `
                         -Destination $startupPath `
                         -Description "Startup items"

    # Configure keyboard settings
    Set-KeyboardConfig

    # Git
    Set-GitConfig -Skip:$SkipGit

    Write-ColoredStatus "Configuration for Windows completed" "DONE"
}
else {
    Write-ColoredStatus "This script is intended for Windows only" "ERROR"
    exit 1
}
