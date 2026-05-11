# 🚪 Offboarding-Automation

Script PowerShell d'automatisation complète du processus de départ d'un employé. Traite en une seule exécution toutes les étapes critiques : désactivation du compte, révocation des licences, transfert des mails, archivage des données et retrait des groupes Azure AD — avec génération d'un rapport HTML professionnel.

> 💡 Projet développé dans le cadre de ma formation en Mastère 2 Architecte Système Réseau et Sécurité, simulant les procédures d'offboarding réalisées en entreprise par les administrateurs systèmes Microsoft 365.

---

## 📋 Fonctionnalités

| Étape | Action | Description |
|-------|--------|-------------|
| 1️⃣ | **Désactivation compte** | Désactive le compte Azure AD de l'employé |
| 2️⃣ | **Révocation licences** | Libère les licences Microsoft 365 |
| 3️⃣ | **Transfert des mails** | Redirige les mails vers le manager |
| 4️⃣ | **Archivage des données** | Archive les données avec horodatage |
| 5️⃣ | **Réinitialisation mot de passe** | Génère un mot de passe temporaire |
| 6️⃣ | **Retrait des groupes** | Retire l'employé de tous les groupes Azure AD |

---

## 📁 Structure du projet
Offboarding-Automation/
│
├── scripts/
│   └── Invoke-Offboarding.ps1      # Script principal d'offboarding
├── data/
│   └── offboarding.csv             # Fichier d'entrée des employés partants
├── reports/
│   └── offboarding-report.html     # Rapport HTML généré automatiquement
├── logs/
│   └── offboarding.log             # Journal horodaté des actions
└── archives/
└── Nom_Prenom_YYYYMMDD/        # Dossiers d'archivage par employé
└── rapport_archivage.txt

---

## 📄 Format du fichier CSV

```csv
Prenom,Nom,Email,Departement,Poste,Manager,DateDepart,Raison
Jean,Dupont,jean.dupont@entreprise.fr,IT,Technicien Support,manager@entreprise.fr,2026-05-31,Demission
Marie,Martin,marie.martin@entreprise.fr,RH,Chargee RH,direction@entreprise.fr,2026-05-31,Fin de contrat
Bob,Moreau,bob.moreau@entreprise.fr,Marketing,Chef de projet,direction@entreprise.fr,2026-06-15,Licenciement
```

### Raisons disponibles

| Raison | Badge |
|--------|-------|
| `Demission` | 🟠 Démission |
| `Fin de contrat` | 🔵 Fin de contrat |
| `Licenciement` | 🔴 Licenciement |

---

## ⚙️ Prérequis

- Windows 10 / 11
- PowerShell 5.1 ou PowerShell 7+
- *(En production)* Module Microsoft.Graph : `Install-Module Microsoft.Graph`
- Aucune dépendance externe pour la version simulation

---

## 🚀 Installation

```powershell
# Cloner le repo
git clone https://github.com/kamgangriki/Offboarding-Automation.git
cd Offboarding-Automation

# Autoriser l'exécution des scripts
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## 📖 Utilisation

### Lancement basique

```powershell
cd scripts
.\Invoke-Offboarding.ps1
```

### Avec paramètres personnalisés

```powershell
.\Invoke-Offboarding.ps1 -CsvPath "C:\data\departs.csv" -OutputHtml "C:\rapports\offboarding.html"
```

**Résultat dans le terminal :**
=== Offboarding Automation ===
Démarrage du processus de départ...
[2026-05-11 12:39:00] [INFO] 3 employé(s) en cours de départ
[2026-05-11 12:39:00] [INFO] === Départ de Jean Dupont ===
[2026-05-11 12:39:00] [SUCCESS] Compte désactivé : jean.dupont@entreprise.fr
[2026-05-11 12:39:00] [SUCCESS] Licences M365 révoquées : jean.dupont@entreprise.fr
[2026-05-11 12:39:00] [SUCCESS] Mails transférés vers : riki.kamgang@entreprise.fr
[2026-05-11 12:39:00] [SUCCESS] Données archivées dans : ..\archives\Dupont_Jean_20260511
[2026-05-11 12:39:00] [SUCCESS] Mot de passe réinitialisé : jean.dupont@entreprise.fr
[2026-05-11 12:39:00] [SUCCESS] Retiré de tous les groupes Azure AD : jean.dupont@entreprise.fr
=== Offboarding terminé ! ===
✅ Employés traités : 3
✅ Actions réussies : 18
❌ Erreurs          : 0

---

## 📊 Aperçu du rapport HTML

Le rapport généré affiche :

- 📊 **4 cartes de statistiques** : employés traités, actions réussies, erreurs, étapes par employé
- 👤 **Fiche détaillée** par employé avec badge de raison (Démission, Fin de contrat, Licenciement)
- ✅ **Tableau des 6 étapes** avec statut et détail pour chaque action
- 🟢 **Lignes vertes** pour les actions réussies
- 🔴 **Lignes rouges** pour les erreurs éventuelles
- 📧 **Manager notifié** affiché en bas de chaque fiche

---

## 🔧 En production avec Microsoft Graph API

```powershell
# Connexion
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# Désactiver le compte
Update-MgUser -UserId "jean.dupont@entreprise.fr" -AccountEnabled $false

# Révoquer les licences
Set-MgUserLicense -UserId "jean.dupont@entreprise.fr" -RemoveLicenses @("licence-id") -AddLicenses @()

# Retirer des groupes
$groups = Get-MgUserMemberOf -UserId "jean.dupont@entreprise.fr"
foreach ($group in $groups) {
    Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $userId
}

# Transférer les mails
Set-MailboxAutoReplyConfiguration -Identity "jean.dupont@entreprise.fr" -AutoReplyState Enabled
Add-MailboxPermission -Identity "jean.dupont@entreprise.fr" -User "manager@entreprise.fr" -AccessRights FullAccess
```

---

## 🛠️ Technologies utilisées

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Microsoft 365](https://img.shields.io/badge/Microsoft_365-D83B01?style=for-the-badge&logo=microsoft-office&logoColor=white)
![Azure AD](https://img.shields.io/badge/Azure_AD-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)
![CSV](https://img.shields.io/badge/CSV-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)

---

## 🔮 Évolutions prévues

- [ ] Connexion réelle à **Microsoft Graph API**
- [ ] Notification automatique par email au manager
- [ ] Sauvegarde OneDrive avant archivage
- [ ] Rapport PDF exportable
- [ ] Intégration avec un système de tickets (GLPI, Jira)
- [ ] Interface graphique PowerShell (WPF)

---

## 👤 Auteur

**Riki Kamgang**
- 📧 rikikamgang@gmail.com
- 💼 [LinkedIn](https://linkedin.com/in/rikikamgang)
- 🐙 [GitHub](https://github.com/kamgangriki)
- 🎓 Mastère 2 Architecte Système Réseau et Sécurité — PMN Paris

---

## 📄 Licence

Ce projet est sous licence MIT — libre d'utilisation et de modification.
