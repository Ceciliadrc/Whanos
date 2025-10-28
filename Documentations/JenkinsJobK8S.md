@import "Style/styles_epitech_stage.less"

# Jenkins job Kubernetes

## Whanos.yaml example
```yaml
deployment:
  replicas: 3
  resources:
    limits:
      cpu: 2
      memory: "128M"
    requests:
      cpu: 4
      memory: "64M"
  ports:
    - 3000
    - 8080
    - 9000
```

#### Le script va:

- Récupérer le nombre de replicas (Valeur par défaut: 1)
```bash
REPLICAS=3

REPLICAS_DEFAULT=1
```

- Récupérer les resources
```bash
LIM_MEM=128M
LIM_CPU=2
REQ_MEM=64M
LIM_CPU=4
```

- Récupérer les ports et enregistrer le premier à part (ici 3000)
``` bash
PORTS=[3000, 8080, 9000]
FIRST_PORT=3000
```

#### en suivant il va:

- Construire le bloc de resources avec les informations récupérées (Si pas de resources récupérées, pas de bloc)
```yaml
  resources:
    limits:
      cpu: $LIM_CPU
      memory: $LIM_MEM
    requests:
      cpu: $REQ_cpu
      memory: $REQ_MEM
```

- Construire les blocs de ports avec les informations récupérées (Si pas de ports récupérés, pas de bloc)
```yaml
PORTS=[3000, 8080, 9000]

# Deployment.yaml
  - name: web-PORTS[0]
    containerPort: PORTS[0]
  - name: web-PORTS[1]
    containerPort: PORTS[1]
  - name: web-PORTS[2]
    containerPort: PORTS[2]
# Soit
  - name: web-3000
    containerPort: 3000
  - name: web-8080
    containerPort: 8080
  - name: web-9000
    containerPort: 9000


#Service.yaml
  - name: web-3000
    port: 3000
    targetPort: 3000
  - name: web-8080
    port: 8080
    targetPort: 8080
  - name: web-9000
    port: 9000
    targetPort: 9000
# Soit
  - name: web-3000
    port: 3000
    targetPort: 3000
  - name: web-8080
    port: 8080
    targetPort: 8080
  - name: web-9000
    port: 9000
    targetPort: 9000
```

#### Il va enregistrer tout ça puis:

- Remplacer tous les placeholders des <a href="K8S_templatesFiles.md">fichiers templates</a> à générer