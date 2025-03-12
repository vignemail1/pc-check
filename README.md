# pc-check

## In english

PC Check Script

This PowerShell script collects various system information for analysis.

### Collected Information

- **Running Processes**: Details about all running processes, including name, ID, path, start time, working set, and CPU usage.
- **System Files**: Lists of executable files (.exe, .dll, .ps1, .bat) found on all mounted drives, excluding protected folders.
- **USB Devices**: Information about connected USB devices, including description, manufacturer, model, driver version, and serial number.
- **PCI Devices**: Details about PCI slots and devices, including slot designation, status, and device information.
- **Disks and Volumes**: Information about disks and volumes, including disk type and volume status.
- **Network Connections**: Current network connections, including protocol, local and remote addresses.
- **WMI Information**: Processor, BIOS, and system details collected via WMI.
- **Windows Event Logs**: Recent event logs from various Windows Event log categories.
- **PNP Entities**: List of Plug and Play entities on the system.

### Running the Script

1. Ensure PowerShell is installed on your system.
1. Save the script as a .ps1 file (e.g., `pc-check.ps1`).
1. Open PowerShell as an administrator.
1. Navigate to the directory where you saved the script using cd.
1. Run the script by typing `.\pc-check.ps1`.

### Output Location

The script creates a directory named `C:\PCCheck` where all collected data is stored. Inside this directory, you will find:

- `GeneralLog.txt`: A log file containing any errors encountered during execution.
- `Processes.txt`, `SystemFiles.txt`, `UsbDevices.txt`, `PciDevices.txt`, `DisksAndVolumes.txt`, `NetworkConnections.txt`, `WmiInfo.txt`, `PnpEntities.txt`: Files containing the respective collected information.
- `eventlogs`: A subdirectory containing Windows Event logs for each log category.

## En francais

Script de vérification PC

Ce script PowerShell collecte diverses informations système pour analyse.

### Informations collectées

- **Processus en cours d'exécution** : Détails sur tous les processus en cours, y compris le nom, l'ID, le chemin, l'heure de démarrage, la mémoire allouée et l'utilisation du processeur.
- **Fichiers système** : Listes de fichiers exécutables (.exe, .dll, .ps1, .bat) trouvés sur tous les lecteurs montés, à l'exception des dossiers protégés.
- **Périphériques USB** : Informations sur les périphériques USB connectés, y compris la description, le fabricant, le modèle, la version du pilote et le numéro de série.
- **Périphériques PCI** : Détails sur les emplacements PCI et les périphériques, y compris la désignation de l'emplacement, le statut et les informations sur le périphérique.
- **Disques et volumes** : Informations sur les disques et volumes, y compris le type de disque et le statut du volume.
- **Connexions réseau** : Connexions réseau actuelles, y compris le protocole, les adresses locales et distantes.
- **Informations WMI** : Détails sur le processeur, la BIOS et le système collectés via WMI.
- **Logs Windows Event** : Logs d'événements récents provenant de diverses catégories de logs Windows Event.
- **Entités PNP** : Liste des entités Plug and Play sur le système.

### Exécution du script

1. Assurez-vous que PowerShell est installé sur votre système.
1. Enregistrez le script sous forme de fichier .ps1 (par exemple, `pc-check.ps1`).
1. Ouvrez PowerShell en tant qu'administrateur.
1. Accédez au répertoire où vous avez enregistré le script à l'aide de cd.
1. Exécutez le script en tapant `.\pc-check.ps1`.

### Emplacement de sortie

Le script crée un répertoire nommé `C:\PCCheck` où toutes les données collectées sont stockées. À l'intérieur de ce répertoire, vous trouverez :

- `GeneralLog.txt` : Un fichier journal contenant toutes les erreurs rencontrées lors de l'exécution.
- `Processes.txt`, `SystemFiles.txt`, `UsbDevices.txt`, `PciDevices.txt`, `DisksAndVolumes.txt`, `NetworkConnections.txt`, `WmiInfo.txt`, `PnpEntities.txt` : Fichiers contenant les informations collectées respectives.
- `eventlogs` : Un sous-répertoire contenant les logs Windows Event pour chaque catégorie de log.
