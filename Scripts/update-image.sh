#!/bin/bash
set -e

# 📥 Arguments
GIT_REPO_URL=$1
OVERLAY=$2
APP_NAME=$3
NEW_IMAGE=$4
CONTAINER_NAME=$5
ACCESS_TOKEN=$6

BRANCH="main"

if [ "$#" -ne 6 ]; then
  echo "Uso: $0 <git_repo_url> <overlay> <app_name> <image> <container_name> <system_access_token>"
  exit 1
fi

# 📁 Clone into temp directory
WORKDIR=$(mktemp -d)
echo "📁 Cloning into $WORKDIR"

# ✅ Configure Git credentials using System.AccessToken
git config --global credential.helper store
echo "https://azure:$ACCESS_TOKEN@dev.azure.com" > ~/.git-credentials

# 🔄 Clone
git clone --branch "$BRANCH" "$GIT_REPO_URL" "$WORKDIR"
cd "$WORKDIR"

OVERLAY_PATH="Overlays/$OVERLAY/$APP_NAME"

# ✅ Validate overlay path
if [ ! -d "$OVERLAY_PATH" ]; then
  echo "❌ App '$APP_NAME' not found in overlay '$OVERLAY'. Expected path: $OVERLAY_PATH"
  rm -rf "$WORKDIR"
  exit 1
fi

if [ ! -f "$OVERLAY_PATH/kustomization.yaml" ]; then
  echo "❌ Missing kustomization.yaml in: $OVERLAY_PATH"
  rm -rf "$WORKDIR"
  exit 1
fi

cd "$OVERLAY_PATH"

# 🔧 Update image
echo "🔧 Updating image: $CONTAINER_NAME → $NEW_IMAGE"
kustomize edit set image "$CONTAINER_NAME=$NEW_IMAGE"

# ✅ Commit and push
cd "$WORKDIR"
git add "$OVERLAY_PATH/kustomization.yaml"
git commit -m "🔄 Update image for $APP_NAME ($OVERLAY): $NEW_IMAGE"
git push origin "$BRANCH"

# 🧹 Cleanup
rm -rf "$WORKDIR"
echo "✅ Done. Cleaned up $WORKDIR"
