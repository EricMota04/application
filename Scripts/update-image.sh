#!/bin/bash

set -e

# 📥 Argumentos
GIT_REPO_URL=$1         # ej: https://<USER>:<PAT>@dev.azure.com/org/project/_git/repo
OVERLAY=$2              # ej: qa
APP_NAME=$3             # ej: my-api
NEW_IMAGE=$4            # ej: myregistry.azurecr.io/my-api:v2.1.3
CONTAINER_NAME=$5       # ej: my-api

BRANCH="main"

if [ "$#" -ne 5 ]; then
  echo "Uso: $0 <git_repo_url> <overlay> <app_name> <image> <container_name>"
  exit 1
fi

# 📁 Crear y clonar en carpeta temporal
WORKDIR=$(mktemp -d)
echo "📁 Clonando en $WORKDIR"
git clone --branch "$BRANCH" "$GIT_REPO_URL" "$WORKDIR"
cd "$WORKDIR"

OVERLAY_PATH="overlays/$OVERLAY/$APP_NAME"

# ✅ Validar que la carpeta del app exista
if [ ! -d "$OVERLAY_PATH" ]; then
  echo "❌ El app '$APP_NAME' no existe en el overlay '$OVERLAY'. Ruta esperada: $OVERLAY_PATH"
  rm -rf "$WORKDIR"
  exit 1
fi

# ✅ Validar que exista el kustomization.yaml
if [ ! -f "$OVERLAY_PATH/kustomization.yaml" ]; then
  echo "❌ No se encontró: $OVERLAY_PATH/kustomization.yaml"
  rm -rf "$WORKDIR"
  exit 1
fi

cd "$OVERLAY_PATH"

# 🛠️ Cambiar imagen
echo "🔧 Cambiando imagen: $CONTAINER_NAME → $NEW_IMAGE"
kustomize edit set image "$CONTAINER_NAME=$NEW_IMAGE"

# 📤 Commit y push
cd "$WORKDIR"
git add "$OVERLAY_PATH/kustomization.yaml"
git commit -m "🔄 Actualización de imagen para $APP_NAME ($OVERLAY): $NEW_IMAGE"
git push origin "$BRANCH"

# 🧹 Limpiar
rm -rf "$WORKDIR"
echo "🧹 Carpeta temporal eliminada: $WORKDIR"
echo "✅ Script finalizado correctamente."
