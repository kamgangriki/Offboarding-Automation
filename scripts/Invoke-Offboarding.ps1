# ============================================
# Invoke-Offboarding.ps1
# Automatisation du départ d'un employé
# Auteur : Riki Kamgang
# ============================================

param(
    [string]$CsvPath = "..\data\offboarding.csv",
    [string]$OutputHtml = "..\reports\offboarding-report.html",
    [string]$LogPath = "..\logs\offboarding.log",
    [string]$ArchivePath = "..\archives"
)

# ── FONCTIONS UTILITAIRES ──
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logLine
    switch ($Level) {
        "INFO"    { Write-Host $logLine -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logLine -ForegroundColor Green }
        "WARNING" { Write-Host $logLine -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logLine -ForegroundColor Red }
    }
}

function Invoke-OffboardingUser {
    param($User)

    $displayName = "$($User.Prenom) $($User.Nom)"
    $actions = @()

    Write-Log "=== Départ de $displayName ===" "INFO"

    # ── ÉTAPE 1 : Désactiver le compte ──
    try {
        # En prod : Update-MgUser -UserId $User.Email -AccountEnabled $false
        Write-Log "Compte désactivé : $($User.Email)" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="1"; Action="Désactivation compte"; Statut="✅ OK"; Detail="Compte Azure AD désactivé" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="1"; Action="Désactivation compte"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    # ── ÉTAPE 2 : Révoquer les licences ──
    try {
        # En prod : Set-MgUserLicense -UserId $User.Email -RemoveLicenses @("licence-id")
        Write-Log "Licences M365 révoquées : $($User.Email)" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="2"; Action="Révocation licences M365"; Statut="✅ OK"; Detail="Licences Microsoft 365 libérées" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="2"; Action="Révocation licences M365"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    # ── ÉTAPE 3 : Transférer les mails vers le manager ──
    try {
        # En prod : Set-MailboxAutoReplyConfiguration + Add-MailboxPermission
        Write-Log "Mails transférés vers : $($User.Manager)" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="3"; Action="Transfert des mails"; Statut="✅ OK"; Detail="Mails transférés vers $($User.Manager)" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="3"; Action="Transfert des mails"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    # ── ÉTAPE 4 : Archiver les données ──
    try {
        $archiveFolder = "$ArchivePath\$($User.Nom)_$($User.Prenom)_$(Get-Date -Format 'yyyyMMdd')"
        New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
        
        # Créer un fichier de rapport d'archivage
        $archiveContent = @"
Rapport d'archivage — $displayName
Date de départ : $($User.DateDepart)
Raison : $($User.Raison)
Email : $($User.Email)
Département : $($User.Departement)
Manager : $($User.Manager)
Date d'archivage : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        $archiveContent | Out-File -FilePath "$archiveFolder\rapport_archivage.txt" -Encoding UTF8
        Write-Log "Données archivées dans : $archiveFolder" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="4"; Action="Archivage des données"; Statut="✅ OK"; Detail="Archivé dans $archiveFolder" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="4"; Action="Archivage des données"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    # ── ÉTAPE 5 : Réinitialiser le mot de passe ──
    try {
        # En prod : Update-MgUser -UserId $User.Email -PasswordProfile @{ForceChangePasswordNextSignIn=$true; Password="TempPass@123"}
        Write-Log "Mot de passe réinitialisé : $($User.Email)" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="5"; Action="Réinitialisation mot de passe"; Statut="✅ OK"; Detail="Mot de passe temporaire généré" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="5"; Action="Réinitialisation mot de passe"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    # ── ÉTAPE 6 : Retirer des groupes ──
    try {
        # En prod : Get-MgUserMemberOf | Remove-MgGroupMemberByRef
        Write-Log "Retiré de tous les groupes Azure AD : $($User.Email)" "SUCCESS"
        $actions += [PSCustomObject]@{ Etape="6"; Action="Retrait des groupes Azure AD"; Statut="✅ OK"; Detail="Retiré de tous les groupes de sécurité" }
    } catch {
        $actions += [PSCustomObject]@{ Etape="6"; Action="Retrait des groupes Azure AD"; Statut="❌ Erreur"; Detail=$_.Exception.Message }
    }

    return [PSCustomObject]@{
        DisplayName = $displayName
        Email       = $User.Email
        Departement = $User.Departement
        Poste       = $User.Poste
        Manager     = $User.Manager
        DateDepart  = $User.DateDepart
        Raison      = $User.Raison
        Actions     = $actions
        Succes      = ($actions | Where-Object { $_.Statut -like "*OK*" }).Count
        Erreurs     = ($actions | Where-Object { $_.Statut -like "*Erreur*" }).Count
    }
}

# ── DÉBUT DU SCRIPT ──
Write-Host "=== Offboarding Automation ===" -ForegroundColor Cyan
Write-Host "Démarrage du processus de départ..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $OutputHtml) -Force | Out-Null
New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null

Write-Log "Démarrage de l'offboarding" "INFO"

if (-not (Test-Path $CsvPath)) {
    Write-Log "Fichier CSV introuvable : $CsvPath" "ERROR"
    exit 1
}

$users = Import-Csv -Path $CsvPath -Delimiter ","
Write-Log "$($users.Count) employé(s) en cours de départ" "INFO"

$results = @()
foreach ($user in $users) {
    $result = Invoke-OffboardingUser -User $user
    $results += $result
}

Write-Log "Offboarding terminé — $($results.Count) employé(s) traité(s)" "INFO"

# ── GÉNÉRATION HTML ──
Write-Host "`nGénération du rapport HTML..." -ForegroundColor Yellow

$dateGeneration = Get-Date -Format "dd/MM/yyyy à HH:mm"
$totalSucces = ($results | Measure-Object -Property Succes -Sum).Sum
$totalErreurs = ($results | Measure-Object -Property Erreurs -Sum).Sum

$cards = ""
foreach ($r in $results) {
    $raisonBadge = switch ($r.Raison) {
        "Demission"      { "<span class='badge orange'>🚪 Démission</span>" }
        "Fin de contrat" { "<span class='badge blue'>📋 Fin de contrat</span>" }
        "Licenciement"   { "<span class='badge red'>❌ Licenciement</span>" }
        default          { "<span class='badge gray'>❓ Autre</span>" }
    }

    $actionsRows = ""
    foreach ($a in $r.Actions) {
        $statutCss = if ($a.Statut -like "*OK*") { "success-row" } else { "error-row" }
        $actionsRows += "<tr class='$statutCss'>
            <td><strong>Étape $($a.Etape)</strong></td>
            <td>$($a.Action)</td>
            <td>$($a.Statut)</td>
            <td>$($a.Detail)</td>
        </tr>"
    }

    $cards += "<div class='employee-card'>
        <div class='employee-header'>
            <div>
                <h3>👤 $($r.DisplayName)</h3>
                <p>$($r.Email) — $($r.Departement) — $($r.Poste)</p>
            </div>
            <div class='employee-meta'>
                $raisonBadge
                <span class='badge gray'>📅 Départ : $($r.DateDepart)</span>
                <span class='badge green'>✅ $($r.Succes) OK</span>
                $(if ($r.Erreurs -gt 0) { "<span class='badge red'>❌ $($r.Erreurs) erreurs</span>" })
            </div>
        </div>
        <table>
            <tr><th>Étape</th><th>Action</th><th>Statut</th><th>Détail</th></tr>
            $actionsRows
        </table>
        <p class='manager-info'>📧 Manager notifié : $($r.Manager)</p>
    </div>"
}

$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Offboarding Report</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Segoe UI, sans-serif; background: #f0f2f5; }
        .header { background: linear-gradient(135deg, #1a237e, #0d47a1); color: white; padding: 25px 40px; }
        .header h1 { font-size: 26px; margin-bottom: 8px; }
        .header p { opacity: 0.8; font-size: 13px; }
        .container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
        .stats { display: flex; gap: 15px; margin-bottom: 25px; flex-wrap: wrap; }
        .stat { background: white; border-radius: 10px; padding: 20px 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.08); flex: 1; min-width: 140px; border-top: 4px solid #0d47a1; }
        .stat h2 { font-size: 32px; color: #0d47a1; margin-bottom: 5px; }
        .stat p { font-size: 13px; color: #666; }
        .stat.green { border-top-color: #388e3c; } .stat.green h2 { color: #388e3c; }
        .stat.red { border-top-color: #d32f2f; } .stat.red h2 { color: #d32f2f; }
        .stat.orange { border-top-color: #f57c00; } .stat.orange h2 { color: #f57c00; }
        .employee-card { background: white; border-radius: 10px; padding: 25px; box-shadow: 0 2px 10px rgba(0,0,0,0.08); margin-bottom: 20px; }
        .employee-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px; flex-wrap: wrap; gap: 10px; }
        .employee-header h3 { font-size: 18px; color: #1a237e; margin-bottom: 5px; }
        .employee-header p { font-size: 13px; color: #666; }
        .employee-meta { display: flex; gap: 8px; flex-wrap: wrap; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #0d47a1; color: white; padding: 10px 14px; text-align: left; font-size: 13px; }
        td { padding: 10px 14px; border-bottom: 1px solid #f0f0f0; font-size: 13px; }
        .success-row { background: #f1f8e9; }
        .error-row { background: #ffebee; }
        .badge { padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: bold; color: white; display: inline-block; }
        .badge.green { background: #388e3c; }
        .badge.red { background: #d32f2f; }
        .badge.orange { background: #f57c00; }
        .badge.blue { background: #1565c0; }
        .badge.gray { background: #757575; }
        .manager-info { margin-top: 10px; font-size: 12px; color: #666; font-style: italic; }
        .footer { text-align: center; color: #999; font-size: 12px; padding: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚪 Rapport d'Offboarding</h1>
        <p>Généré le $dateGeneration | Administrateur : Riki Kamgang</p>
    </div>
    <div class="container">
        <div class="stats">
            <div class="stat"><h2>$($results.Count)</h2><p>Employés traités</p></div>
            <div class="stat green"><h2>$totalSucces</h2><p>Actions réussies</p></div>
            <div class="stat red"><h2>$totalErreurs</h2><p>Erreurs</p></div>
            <div class="stat orange"><h2>6</h2><p>Étapes par employé</p></div>
        </div>
        $cards
        <p class="footer">Offboarding-Automation — Riki Kamgang | github.com/kamgangriki | linkedin.com/in/rikikamgang</p>
    </div>
</body>
</html>
"@

$html | Out-File -FilePath $OutputHtml -Encoding UTF8
Write-Log "Rapport HTML généré : $OutputHtml" "SUCCESS"
Start-Process $OutputHtml
Write-Host "`n=== Offboarding terminé ! ===" -ForegroundColor Cyan
Write-Host "✅ Employés traités : $($results.Count)" -ForegroundColor Green
Write-Host "✅ Actions réussies : $totalSucces" -ForegroundColor Green
Write-Host "❌ Erreurs         : $totalErreurs" -ForegroundColor Red
