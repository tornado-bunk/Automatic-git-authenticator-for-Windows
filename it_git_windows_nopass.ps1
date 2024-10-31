# Verifica se lo script è in esecuzione come amministratore
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRORE: Questo script deve essere eseguito come amministratore." -ForegroundColor Red
    exit
}

# Verifica se la cartella .git esiste nella directory corrente
if (-not (Test-Path .git)) {
    Write-Host "ERRORE: Questo script deve essere eseguito nella directory di una repository Git." -ForegroundColor Red
    exit
}

# Imposta il servizio ssh-agent su avvio automatico
Set-Service -Name ssh-agent -StartupType Automatic

# Avvia il servizio ssh-agent
Start-Service ssh-agent

# Verifica che il servizio sia in esecuzione
do {
    # Controlla lo stato del servizio
    $service = Get-Service -Name ssh-agent

    # Se il servizio è in esecuzione, esci dal ciclo
    if ($service.Status -eq 'Running') {
        Write-Host "Il servizio ssh-agent e' in esecuzione." -ForegroundColor Green
		Write-Host ""
        break
    } else {
        Write-Host "Attendere che il servizio ssh-agent parta..."
        Start-Sleep -Seconds 2 # Aspetta 2 secondi prima di riprovare
    }
} while ($true)

# Configura il comando ssh per Git
git config core.sshCommand (get-command ssh).Source.Replace('\','/')

# Assegna il percorso della cartella .ssh a una variabile
$sshPath = "$env:USERPROFILE\.ssh"

# Chiedi all'utente di inserire il percorso della chiave
$keyPath = Read-Host -Prompt "Inserisci il percorso della chiave SSH (premi Invio per usare il percorso predefinito: $sshPath\id_ed25519)"
Write-Host ""

# Se l'utente non fornisce un input, usa il percorso predefinito
if (-not [string]::IsNullOrWhiteSpace($keyPath)) {
    $sshKey = $keyPath
} else {
    $sshKey = "$sshPath\id_ed25519"
}

# Aggiungi la chiave SSH all'agente
ssh-add "$sshKey"

# Attendere l'input dell'utente prima di chiudere
Read-Host -Prompt "Premi Invio per continuare..."

# Chiedi all'utente se desidera creare uno script di avvio
$createStartupScript = Read-Host -Prompt "Vuoi creare uno script che dovrai manualmente far partire per impostare la chiave SSH all'avvio di Windows? (S/N)"

if ($createStartupScript -eq 'S' -or $createStartupScript -eq 's') {
    # Definisci il percorso dello script da creare
    $startupScriptPath = "$env:USERPROFILE\ssh_auth_script.ps1"

    # Contenuto dello script
    $scriptContent = @"
# Avvia il servizio ssh-agent
Start-Service ssh-agent

# Aggiungi la chiave SSH all'agente
ssh-add '$sshKey'
"@

    # Salva il contenuto nello script
    Set-Content -Path $startupScriptPath -Value $scriptContent

    Write-Host "Lo script di avvio e' stato creato in: $startupScriptPath"
    Write-Host "Puoi eseguire questo script manualmente all'avvio di Windows."
	Write-Host ""
} else {
    Write-Host "Nessun script e' stato creato."
	Write-Host ""
	exit
}

# Chiedi se si desidera aggiungere un alias per lo script nel profilo di PowerShell
$addToProfile = Read-Host -Prompt "Vuoi aggiungere il comando 'auth' per eseguire automaticamente lo script di autenticazione? (S/N)"
Write-Host ""

if ($addToProfile -eq 'S' -or $addToProfile -eq 's') {
    # Percorso del file di profilo di PowerShell
    $profilePath = $PROFILE

    # Contenuto da aggiungere al profilo
    $aliasCommand = "Set-Alias auth '$startupScriptPath'"

    # Aggiungi il comando al profilo se non esiste già
    if (-not (Select-String -Path $profilePath -Pattern 'Set-Alias auth')) {
        Add-Content -Path $profilePath -Value $aliasCommand
        Write-Host "Alias 'auth' e' stato aggiunto al file di profilo di PowerShell." -ForegroundColor Green
		Write-Host "All' avvio di Windows, nel terminale, dovrai scrivere 'auth' per far partire lo script di autenticazione" -ForegroundColor Blue
		Write-Host "RIAVVIA IL TERMINALE PER RENDERE EFFETTIVE LE MODIFICHE." -ForegroundColor Red
    } else {
        Write-Host "L'alias 'auth' esiste già nel file di profilo di PowerShell." -ForegroundColor Red
    }
} else {
    Write-Host "Nessun alias e' stato aggiunto al profilo di PowerShell." -ForegroundColor Blue
	exit
}
