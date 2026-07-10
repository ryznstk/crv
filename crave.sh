#!/bin/bash
set -e

# ================================
# Project Configuration
# ================================
export PROJECTFOLDER="VOS"
export PROJECTID="82"
export REPO_INIT="https://github.com/PixelOS-AOSP/android_manifest -b sixteen --git-lfs --depth=1"
export BUILD_DIFFERENT_ROM="repo init -u https://github.com/VoltageOS/manifest.git -b 16.2 --git-lfs --depth 1"
# ================================
# Destroy Old Clones
# ================================
echo ">>> Cleaning old clone"
if (grep -q "$PROJECTFOLDER" <(crave clone list --json | jq -r '.clones[]."Cloned At"')) || [ "${DCDEVSPACE}" == "1" ]; then
  crave clone destroy -y /crave-devspaces/$PROJECTFOLDER || echo "Error removing $PROJECTFOLDER"
else
  rm -rf $PROJECTFOLDER || true
fi

# ================================
# Create New Clone
# ================================
echo ">>> Creating new clone"
if [ "${DCDEVSPACE}" == "1" ]; then
  crave clone create --projectID $PROJECTID /crave-devspaces/$PROJECTFOLDER || echo "Crave clone create failed!"
  cd /crave-devspaces/$PROJECTFOLDER
else
  mkdir $PROJECTFOLDER && cd $PROJECTFOLDER
  echo "Running $REPO_INIT"
  $REPO_INIT
fi

# ================================
# Run inside Crave devspace
# ================================
crave run --no-patch -- "
  # ================================
  # Clean old manifests
  # ================================
  rm -rf .repo/local_manifests
  rm -rf device/xiaomi/peridot
  rm -rf out/target/product/peridot
  
  # ================================
  # Initialize AxionAOSP repo
  # ================================
  echo '>>> Initializing Lunaris repo'
  $BUILD_DIFFERENT_ROM

  # ================================
  # Clone local manifests
  # ================================
  echo '>>> Cloning local manifests'
  #git clone https://github.com/ryznstk/manifest.git -b main .repo/local_manifests/
  git clone -b vos https://github.com/ryznstk/pure.git device/xiaomi/peridot

  # ================================
  # Sync sources
  # ================================
  echo '>>> Syncing sources'
  /opt/crave/resync.sh

  # ================================
  # Setup build environment
  # ================================
  . build/envsetup.sh

  # ================================
  # Build
  # ================================
  echo '>>> Starting build'
  lunch voltage_peridot-bp4a-user
  make installclean
  m bacon
"
