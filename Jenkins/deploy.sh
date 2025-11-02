#!/bin/bash
set -e

PROJECT_NAME="$1"
WORKSPACE="$JENKINS_HOME/workspace/$PROJECT_NAME"
REGISTRY="localhost:5000"
IMAGE_NAME="$REGISTRY/whanos-$PROJECT_NAME:latest"

echo "Starting deployment for project: $PROJECT_NAME"
cd "$WORKSPACE"

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
    else
        echo "unknown"
    fi
}

# Build and push image
echo "Detecting application language in progress"
LANGUAGE=$(detect_language)

if [ "$LANGUAGE" = "unknown" ]; then
    echo "ERROR: Could not detect supported language"
    exit 1
fi

echo "Detected language: $LANGUAGE"

echo "Building Docker image in progress"
if [ -f "Dockerfile" ]; then
    echo "Using Dockerfile"
    docker build -t "$IMAGE_NAME" .
else
    echo "Using standalone Dockerfile"
    docker build -t "$IMAGE_NAME" -f "/Jenkins/images/$LANGUAGE/Dockerfile.standalone" .
fi

echo "Pushing image to registry in progress"
docker push "$IMAGE_NAME"

echo "Checking for deployment configuration in progress"
if [ -f "whanos.yml" ]; then
    echo "Found whanos.yml, triggering deployment pipeline in progress"

    YAML_CONTENT=$(cat whanos.yml)

    JENKINS_TOKEN=$(cat Jenkins/secrets/initialAdminPassword)

    curl -X POST "http://localhost:8080/job/Deployments/job/whanos-deploy/buildWithParameters" \
        --user "admin:${JENKINS_TOKEN}" \
        --form "IMAGE_URL=${IMAGE_NAME}" \
        --form "APP_NAME=${PROJECT_NAME}" \
        --form "YAML_CONTENT=${YAML_CONTENT}"

    echo "Deployment pipeline triggered successfully!"
else
    echo "No whanos.yml found, skipping Kubernetes deployment"
    echo "Image built and pushed to: $IMAGE_NAME"
fi

echo "Deployment process completed for $PROJECT_NAME"