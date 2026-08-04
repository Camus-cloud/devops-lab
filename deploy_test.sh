#!/bin/bash
set -euo pipefail
echo "Début du déploiement"
cp fichier_inexistant.py /tmp/app_deployed.py || { echo "Échec de la copie"; exit 1; }
echo "Déploiement terminé"
