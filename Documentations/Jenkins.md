# Documentation Jenkins Whanos

## Qu'est-ce que Jenkins ?

### Définition
Jenkins est un serveur d'automatisation open source utilisé pour implémenter l'intégration continue et la livraison continue (CI/CD). Il permet d'automatiser les différentes étapes du développement logiciel, depuis la compilation du code jusqu'au déploiement en production.

### Fonctionnement
Jenkins fonctionne comme un orchestrateur qui :
- Surveille les dépôts de code source
- Détecte les changements (commits, merges)
- Lance automatiquement des processus de construction et de test
- Génère des rapports sur l'état des builds

## Configuration de l'Instance Jenkins Whanos

### Méthode de Configuration
L'instance utilise Configuration as Code (JCasC), il s'agit d'une configuration via le fichier `jenkins.yml`

### Configuration de Sécurité

**Authentification**
- Mode authentification locale activé
- Utilisateur unique : `admin`
- Mot de passe : variable `${ADMIN_PASSWORD}`
- Inscription désactivée (`allowSignup: false`)

**Autorisations**
- Stratégie Role-Based Authorization
- Rôle "admin" avec permission `Overall/Administer`
- Assignation à l'utilisateur "admin"

**Sécurité des Scripts**
- Signatures Groovy approuvées prédéfinies :
  - `java.lang.Process getInputStream`
  - `java.lang.Process waitFor`
  - `DefaultGroovyMethods execute`

## Structure des Dossiers Jenkins

### Organisation

```
Jenkins Whanos
├── Whanos base images/
│   ├── whanos-c
│   ├── whanos-java
│   ├── whanos-javascript
│   ├── whanos-python
│   ├── whanos-befunge
│   └── Build all base images
├── Projects/
│   └── [jobs créés dynamiquement]
└── Deployments/
    └── whanos-deploy
```

## Configuration des Jobs Jenkins

### Jobs d'Images de Base

**Structure**
- Type : Freestyle project
- Paramètre string : `IMAGE_NAME_[LANGAGE]`
- Wrapper : Pre-build cleanup
- Step : Commande shell de build Docker

**Exemple de Configuration C**
```groovy
job('Whanos base images/whanos-c') {
    parameters {
        stringParam('IMAGE_NAME_C', '', 'Image name for C')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_C} -f images/c/Dockerfile.base .')
    }
}
```

### Job "Build all base images"

**Fonctionnalités**
- Déclenche tous les jobs d'images de base en parallèle
- Utilise la construction parallèle Jenkins
- Structure en stage et steps

### Job link-project

**Objectif**
Créer dynamiquement des jobs pour de nouveaux dépôts Git

**Paramètres**
- `REPO_URL` : URL du dépôt Git
- `PROJECT_NAME` : Nom du job à créer

**Fonctionnement**
- Utilise la DSL Jenkins pour générer du code
- Crée un job freestyle dans le dossier Projects
- Configure SCM Git avec la branche main
- Planification SCM toutes les 5 minutes

### Pipeline whanos-deploy

- Type : Pipeline Job
- Définition : SCM avec Jenkinsfile

## Script de Déploiement deploy.sh

### Fonctionnalités

**Détection de Langage**
- Analyse la structure du projet
- Supporte 5 langages : C, Java, JavaScript, Python, Befunge
- Critères de détection basés sur les fichiers présents

**Construction d'Image Docker**
- Utilise le Dockerfile du projet si présent
- Sinon utilise le Dockerfile.standalone approprié
- Build avec le nom d'image formaté

**Enregistrement et Déploiement**
- Push vers le registre local (localhost:5000)
- Détection automatique du fichier whanos.yml
- Déclenchement du pipeline de déploiement

### Variables Utilisées
- `PROJECT_NAME` : Nom du projet
- `WORKSPACE` : Répertoire de travail Jenkins
- `REGISTRY` : Registre Docker local
- `IMAGE_NAME` : Nom complet de l'image
- `LANGUAGE` : Langage détecté

## Ajout d'un Nouveau Langage

### Étapes pour ajouter un Langage

#### 1. Créer les Dockerfiles

Créer les fichiers dans le dossier `images/nouveau-langage/` :

```bash
mkdir -p images/nouveau-langage/
touch images/nouveau-langage/Dockerfile.base
touch images/nouveau-langage/Dockerfile.standalone
```

#### 2. Modifier le script Deploy.sh

Ajouter la logique de détection dans la fonction detect_language() :

```bash
detect_language() {
    if [ -f "app/Makefile" ] || [ -f "Makefile" ]; then
        echo "c"
    elif [ -f "app/pom.xml" ]; then
        echo "java"
    elif [ -f "app/package.json" ]; then
        echo "javascript"
    elif [ -f "app/requirements.txt" ]; then
        echo "python"
    elif [ -f "app/main.bf" ] && [ $(find app -name "*.bf" | wc -l) -eq 1 ]; then
        echo "befunge"
    elif [ -f "app/configuration-nouveau-langage" ]; then
        echo "nouveau-langage"
    else
        echo "unknown"
    fi
}
```

#### 3. Ajouter le job dans le job_dsl.groovy

Créer un nouveau job dans la section “Whanos base images” :

```bash
job('Whanos base images/whanos-nouveau-langage') {
    parameters {
        stringParam('IMAGE_NAME_NOUVEAU_LANGAGE', '', 'Image name for Nouveau Langage')
    }
    steps {
        wrappers {
            preBuildCleanup()
        }
        shell('docker build -t ${IMAGE_NAME_NOUVEAU_LANGAGE} -f images/nouveau-langage/Dockerfile.base .')
    }
}
```

#### 4. Mettre à jour le job "Build all base images"

Ajouter le nouveau langage dans la construction :

```bash
job('Whanos base images/Build all base images') {
    stage('Trigger build of all jobs') {
        steps {
            parallel (
                c: {
                    build job: 'Whanos base images/whanos-c'
                },
                java: {
                    build job: 'Whanos base images/whanos-java'
                },
                javascript: {
                    build job: 'Whanos base images/whanos-javascript'
                },
                python: {
                    build job: 'Whanos base images/whanos-python'
                },
                befunge: {
                    build job: 'Whanos base images/whanos-befunge'
                },
                nouveauLangage: {
                    build job: 'Whanos base images/whanos-nouveau-langage'
                }
            )
        }
    }
}
```
