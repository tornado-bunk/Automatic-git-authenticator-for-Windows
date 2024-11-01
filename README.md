# PowerShell SSH Authentication Script for Git

This repository contains a PowerShell script that simplifies SSH key authentication for use with Git. The script configures the `ssh-agent` service, adds the specified SSH key, and creates an alias for quick access.

## Prerequisites

- PowerShell (version 5.1 or higher)
- Git installed
- OpenSSH Client installed

## Installation

1. **Clone the repository** to your local machine:

   ```bash
   git clone https://github.com/tornado-bunk/Automatic-git-authenticator-for-Windows.git

2. Run the script as an **administrator**:

    - Open PowerShell (or Windows Terminal) as an administrator.
    - Type ```Set-ExecutionPolicy Unrestricted``` to allow running unsigned script
    - Copy the file "en_git_windows_nopass.ps1" in your repository folder. (Or "it_git_windows_nopass.ps1" if you want the italian version)
    - Execute the script with ".\en_git_windows_nopass.ps1"

3. Follow the instructions.

4. Type ```Set-ExecutionPolicy Allsigned``` to restore back the default secutity script policy of Windows.
