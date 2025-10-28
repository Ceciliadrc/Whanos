@import "Style/styles_epitech_stage.less"

# Whanos - Documentation Utilisateur Kubernetes

##  Fonctionnement du job Jenkins Kubernetes

### 1. Paramètres du job

Le pipeline Jenkins prend les paramètres suivants :
- `IMAGE_URL` *(string)* : URL de l’image Docker à déployer.
- `APP_NAME` *(string)* : nom logique de l’application (sert aux noms des manifests).
- `HOST_NAME` *(string, optionnel)* : nom d’hôte pour l’ingress (défaut : `${APP_NAME}.dop.io`).
- `YAML_CONTENT` *(text)* : contenu brut du fichier `whanos.yaml` fourni par l’utilisateur.

<br>

Des variables d’environnement sont dérivées :
- `APP_NAME`, `IMAGE_URL` et `HOST_NAME` (avec valeur par défaut si vide).

<br>

<div class="info-zone">
<strong>Dépendances requises côté agent Jenkins</strong>

- `bash`
- `yq`
- `jq`
- `sed`
- `kubectl`

</div>

---

### 2. Exemple de `whanos.yaml`

```yaml
deployment:
  replicas: 3
  resources:
    limits:
      cpu: "2"
      memory: "128Mi"
    requests:
      cpu: "1"
      memory: "64Mi"
  ports: [3000, 8080, 9000]
```

<div class="warning-zone">
Les unités mémoire doivent être valides côté Kubernetes (<code>Mi</code>, <code>Gi</code>, etc.).
</div>

---

### 3. Étape **Read and Save specs** (parsing)

Le script lit `YAML_CONTENT` et extrait :

**Réplicas** (`REPLICAS`) : `yq '.deployment.replicas // 1'` (défaut : 1)

**Ressources** (`REQ_CPU`, `REQ_MEM`, `LIM_CPU`, `LIM_MEM`) :
  - `yq '.deployment.resources.requests.cpu   // ""'`
  - `yq '.deployment.resources.requests.memory // ""'`
  - `yq '.deployment.resources.limits.cpu     // ""'`
  - `yq '.deployment.resources.limits.memory  // ""'`

<br>

**Ports** :
  - `PORTS_JSON` : tableau JSON via `yq -o=json '.deployment.ports // []'`
  - `FIRST_PORT` : premier port (si présent) via `jq -r '.[0] // empty'`
  - `PORTS` : tableau de tous les ports via `jq -r '.[]'`

<br>

Le script construit ensuite **des blocs YAML textuels** (échappés) à injecter dans les templates :

#### `RESOURCES_BLOCK` (seulement si au moins une valeur est fournie) :

  ```yaml
  requests:
    cpu: "<REQ_CPU>"
    memory: "<REQ_MEM>"
  limits:
    cpu: "<LIM_CPU>"
    memory: "<LIM_MEM>"
  ```

  (les sous-clés `requests`/`limits` ne sont ajoutées que si des valeurs existent)

#### `CONTAINER_PORTS_BLOCK` pour le Deployment :

  ```yaml
  - name: web-<p>
    containerPort: <p>
  ```

  (répété pour chaque port)

#### `SERVICE_PORTS_BLOCK` pour le Service :

  ```yaml
  - name: web-<p>
    port: <p>
    targetPort: <p>
  ```

Tous ces éléments sont **persistés** dans un fichier `.build_env` (via `printf … > .build_env`).

---

### 4. Étape **Render manifests** (templating)

Les fichiers templates suivants sont requis dans le workspace Jenkins :

* `template.deployment.yaml`
* `template.service.yaml`
* `template.ingress.yaml`

<br>

Ils doivent contenir les **placeholders** suivants (remplacés par `sed -i`) :

* `__APP_NAME__`, `__IMAGE_URL__`, `__REPLICAS__`
* `__PORTS__` (section `ports:` du container *ou* supprimée si aucun port)
* `__RESOURCES__` (section `resources:` *ou* supprimée si vide)
* `__APP_NAME_DNS__` (nom du Service pour l’Ingress)
* `__APP_NAME_INGRESS__`, `__HOST_NAME__`, `__PORT__` (premier port pour l’Ingress)

<br>

**Logique de rendu** :

Le template Deployment est copié en `${APP_NAME}.deployment.yaml` puis les placeholders sont remplacés.
   - Si `CONTAINER_PORTS_BLOCK` est vide, la clé `ports:` et le placeholder `__PORTS__` sont supprimés.
   - Si `RESOURCES_BLOCK` est vide, la clé `resources:` et `__RESOURCES__` sont supprimés.

<br>

Si `FIRST_PORT` existe, les templates **Service** et **Ingress** sont rendus :
   - Service `${APP_NAME}.service.yaml` : remplace `__APP_NAME__`, `__APP_NAME_DNS__`, `__PORTS__`.
   - Ingress `${APP_NAME}.ingress.yaml` : remplace `__APP_NAME_INGRESS__`, `__HOST_NAME__`, `__APP_NAME_DNS__`, `__PORT__`.

<br>
<div class="warning-zone">
Si aucun port n’est fourni, <b>aucun Service/Ingress n’est généré</b>.
</div>

<br>
<div class="warning-zone">
<b>Seul le premier port sera exposé</b> dans le Ingress en tant que chemin racine du déploiement web.
</div>

---

### 5. Étape **Apply files** (déploiement)

Application systématique du **Deployment** :

  ```bash
  kubectl apply -f "${APP_NAME}.deployment.yaml"
  ```

<br>

Si un Service a été généré, application du **Service** puis de l’**Ingress** :

  ```bash
  kubectl apply -f "${APP_NAME}.service.yaml"
  kubectl apply -f "${APP_NAME}.ingress.yaml"
  ```

---

<div class="success-note">
Déploiement appliqué. Consultez <code>kubectl get deploy,svc,ingress</code> pour vérifier l'état et <code>kubectl describe</code> / <code>kubectl logs</code> pour diagnostiquer.
</div>

<br>
<br>

<h3>
  <a href="K8S_templatesFiles.md">
  <b>Vous trouverez ici les fichiers templates utilisés.</b>
  </a>
</h3>
