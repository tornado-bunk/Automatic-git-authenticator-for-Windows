# Check if the script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as administrator." -ForegroundColor Red
    exit
}

# Check if .git folder exists in the current directory
if (-not (Test-Path .git)) {
    Write-Host "ERROR: This script must be run in a Git repository directory." -ForegroundColor Red
    exit
}

# Set SSH agent service to automatic startup
Set-Service -Name ssh-agent -StartupType Automatic

# Start the SSH agent service
Start-Service ssh-agent

# Verify the service is running
do {
    # Check service status
    $service = Get-Service -Name ssh-agent

    # If service is running, exit the loop
    if ($service.Status -eq 'Running') {
        Write-Host "The ssh-agent service is running." -ForegroundColor Green
        Write-Host ""
        break
    } else {
        Write-Host "Waiting for ssh-agent service to start..."
        Start-Sleep -Seconds 2 # Wait 2 seconds before retrying
    }
} while ($true)

# Configure SSH command for Git
git config core.sshCommand (get-command ssh).Source.Replace('\','/')

# Assign .ssh folder path to a variable
$sshPath = "$env:USERPROFILE\.ssh"

# Ask user to input SSH key path
$keyPath = Read-Host -Prompt "Enter the SSH key path (press Enter to use default path: $sshPath\id_ed25519)"
Write-Host ""

# If user doesn't provide input, use default path
if (-not [string]::IsNullOrWhiteSpace($keyPath)) {
    $sshKey = $keyPath
} else {
    $sshKey = "$sshPath\id_ed25519"
}

# Add SSH key to the agent
ssh-add "$sshKey"

# Wait for user input before closing
Read-Host -Prompt "Press Enter to continue..."

# Ask user if they want to create a startup script
$createStartupScript = Read-Host -Prompt "Do you want to create a script that you'll manually run to set up the SSH key when you are deauthenticated? (Y/N)"
$addToProfile = Read-Host -Prompt "Do you want to add the 'auth' command to automatically run the authentication script? (Y/N)"


if ($createStartupScript -eq 'Y' -or $createStartupScript -eq 'y') {
    # Define the path for the script to be created
    $startupScriptPath = "$env:USERPROFILE\ssh_auth_script.ps1"

    # Script content
    $scriptContent = @"
# Start the ssh-agent service
Start-Service ssh-agent

# Add SSH key to the agent
ssh-add '$sshKey'
"@

    # Save content to script
    Set-Content -Path $startupScriptPath -Value $scriptContent

    Write-Host "The startup script has been created at: $startupScriptPath"
    Write-Host ""
} else {
    Write-Host "No startup script was created."
    Write-Host ""
    exit
}

Write-Host ""

if ($addToProfile -eq 'Y' -or $addToProfile -eq 'y') {
    # PowerShell profile path
    $profilePath = $PROFILE

    # Command to add to profile
    $aliasCommand = "Set-Alias auth '$startupScriptPath'"

    # Add command to profile if it doesn't already exist
    if (-not (Select-String -Path $profilePath -Pattern 'Set-Alias auth')) {
        Add-Content -Path $profilePath -Value $aliasCommand
        Write-Host "The 'auth' alias has been added to the PowerShell profile." -ForegroundColor Green
        Write-Host "When needed, in the terminal, you need to type 'auth' to run the authentication script" -ForegroundColor Blue
        Write-Host "RESTART THE TERMINAL TO MAKE THE CHANGES EFFECTIVE." -ForegroundColor Red
    } else {
        Write-Host "The 'auth' alias already exists in the PowerShell profile." -ForegroundColor Red
    }
} else {
    Write-Host "No alias was added to the PowerShell profile." -ForegroundColor Blue
    exit
}