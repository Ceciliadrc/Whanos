@import "Style/styles_epitech_stage.less"

# template.deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: __APP_NAME__
  namespace: default
spec:
  replicas: __REPLICAS__
  selector:
    matchLabels:
      app: __APP_NAME__
  template:
    metadata:
      labels:
        app: __APP_NAME__
    spec:
      containers:
        - name: __APP_NAME__
          image: __IMAGE_URL__
          ports:
            __PORTS__
          resources:
            __RESOURCES__
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - __APP_NAME__
              topologyKey: "kubernetes.io/hostname"
```

# template.ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: __APP_NAME_INGRESS__
  namespace: default
spec:
  ingressClassName: traefik
  rules:
    - host: __HOST_NAME__
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: __APP_NAME_DNS__
                port:
                  number: __PORT__
```

# template.service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: __APP_NAME_DNS__
  namespace: default
spec:
  selector:
    app: __APP_NAME__
  ports:
    __PORTS__
  type: ClusterIP
```