# Stage 7 - CI/CD avec Jenkins

## Objectif

Mettre en place un pipeline CI/CD complet declenche automatiquement a
chaque push sur la branche main du repo devops-lab :
checkout -> build image Docker -> push sur GitHub Container Registry
(ghcr.io) -> deploiement rolling update sur le cluster Kubernetes.

## Architecture

- vm-cicd (192.168.100.14) : Jenkins (installe via apt, port 8080)
- github.com/Camus-cloud/devops-lab : source du Jenkinsfile et du code
- ghcr.io/camus-cloud/devops-lab : registry d'images Docker
- vm-k8s-master + 2 workers : cluster kubeadm cible du deploiement

## Pipeline (Jenkinsfile)

Quatre stages declaratifs :

1. Checkout : clone du repo (credential ID `github-creds`)
2. Build Docker Image : `docker build` avec tag = numero de build Jenkins
3. Push to Registry : authentification ghcr.io (credential ID `ghcr-creds`)
   puis push de l'image
4. Deploy to Kubernetes : decodage d'un kubeconfig stocke en base64
   (credential ID `k8s-kubeconfig-b64`), puis `kubectl set image` +
   `kubectl rollout status`

## Credentials Jenkins utilisees

| ID                    | Type                     | Usage                              |
|------------------------|--------------------------|-------------------------------------|
| github-creds           | Username/password        | Clone du repo prive/public          |
| ghcr-creds              | Username/password        | Push d'image vers ghcr.io           |
| k8s-kubeconfig-b64      | Secret text (base64)     | Authentification kubectl            |

## Securite cote cluster

- ServiceAccount dedie `jenkins-deployer` (namespace default) avec
  RoleBinding sur le ClusterRole `edit` (pas de droits cluster-admin)
- Token du ServiceAccount genere avec une duree de vie longue (8760h)
  puis encode en kubeconfig complet, stocke en base64 dans Jenkins
- Secret Kubernetes `ghcr-pull-secret` (docker-registry) associe au
  Deployment myapp via `imagePullSecrets`, necessaire car le package
  ghcr.io est prive

## Declenchement automatique

Poll SCM configure sur le job Jenkins, planning `H/2 * * * *`
(verification toutes les 2 minutes environ). Alternative au webhook
GitHub classique, plus simple a mettre en place sur un reseau NAT
local sans IP publique exposee.

## Incidents rencontres et resolutions

1. Permissions Docker pour l'utilisateur systeme jenkins
   - Symptome : `permission denied ... docker.sock`
   - Cause : `usermod -aG docker jenkins` non pris en compte car
     Jenkins tournait deja avant la modification du groupe
   - Fix : `sudo systemctl restart jenkins` apres l'ajout au groupe

2. Mismatch d'ID de credential (casse)
   - Symptome : stage Push to Registry echoue silencieusement
   - Cause : Jenkinsfile referencait `GHCR-CREDS` (majuscules) alors
     que l'ID reel de la credential etait `ghcr-creds` (minuscules) ;
     l'ID d'une credential Jenkins est immuable apres creation
   - Fix : correction du Jenkinsfile pour utiliser l'ID exact

3. Corruption du kubeconfig lors de copier-coller manuel
   - Symptome : `illegal base64 data at input byte N`, puis plus tard
     `error: You must be logged in to the server`
   - Cause : le copier-coller multi-lignes via le client SSH (PuTTY)
     perdait ou alterait des caracteres sur les gros blocs de texte
   - Fix definitif : script Groovy execute directement dans la
     Script Console Jenkins, lisant le fichier kubeconfig depuis le
     disque du serveur Jenkins et l'injectant dans la credential sans
     aucune etape de copier-coller reseau

4. Erreur de compilation Groovy (`unexpected char 0xFFFF`)
   - Cause : caracteres emoji colles dans le Jenkinsfile, mal
     interpretes par le terminal
   - Fix : suppression de tous les emojis, reecriture en ASCII pur ;
     verification systematique avec `LC_ALL=C grep -n '[^ -~]' Jenkinsfile`
     avant chaque commit

5. ImagePullBackOff sur les nouveaux pods
   - Cause : le package ghcr.io est prive, le cluster n'a aucun moyen
     de s'authentifier lors du pull
   - Fix : creation d'un secret `docker-registry` (imagePullSecret)
     associe au Deployment

6. CrashLoopBackOff apres correction du pull d'image
   - Cause : le conteneur executait un script one-shot
     (`console.log(...)`) qui se terminait immediatement au lieu de
     rester actif ; Kubernetes attend un processus persistant
   - Fix : reecriture de dist/index.js en petit serveur HTTP Node.js
     qui reste a l'ecoute sur le port 80

## Verification finale
Resultat attendu : 3/3 pods Running, Deployment 3/3 READY.

## Points d'amelioration possibles

- Remplacer le Poll SCM par un vrai webhook GitHub si le reseau le
  permet un jour (moins de latence, moins de charge sur Jenkins)
- Ajouter un stage de tests automatises avant le build Docker
- Ajouter des health checks (readiness/liveness probes) sur le
  Deployment myapp pour detecter les crashs plus vite qu'un timeout
  de rollout
- Faire tourner Jenkins avec un volume Docker plutot qu'une install
  systeme, pour faciliter les sauvegardes/migrations
