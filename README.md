# devops-lab

Lab DevOps complet : Linux, Networking, Git, Bash/Python, Docker,
Kubernetes et CI/CD avec Jenkins.

## Etat d'avancement

- Stage 1 - Linux : complete
- Stage 2 - Networking : complete
- Stage 3 - Git/GitHub : complete
- Stage 4 - Bash/Python : complete (sauf 4.3 boto3/EC2 avec LocalStack)
- Stage 5 - Docker : complete
- Stage 6 - Kubernetes : complete (cluster kubeadm 3 noeuds, Calico,
  Ingress-nginx)
- Stage 7 - CI/CD Jenkins : complete, voir docs/STAGE7-CICD.md

## Structure du repo

- `Jenkinsfile` : pipeline CI/CD (build, push, deploy)
- `Dockerfile` : image de l'application
- `dist/index.js` : petit serveur HTTP Node.js
- `package.json` : dependances de l'application
- `check_disk.sh`, `deploy_test.sh`, `read_config.py`, `config.yaml` :
  scripts du Stage 4
- `docs/` : documentation detaillee par stage

## CI/CD

Le pipeline Jenkins est declenche automatiquement a chaque push sur
main (Poll SCM, toutes les 2 minutes) et deploie l'application sur le
cluster Kubernetes local. Voir docs/STAGE7-CICD.md pour le detail de
l'architecture et le journal des incidents rencontres.
