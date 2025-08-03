#!/bin/bash

# Detect OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

# Set the appropriate file and platform directory based on OS and architecture
if [ "$OS" = "Darwin" ]; then
    # macOS - only x86_64 available (ignoring PowerPC)
    file="edcre-v1.1.0-mac-os-x86_64.zip"
    platform="mac"
elif [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        file="edcre-v1.1.0-linux-x86_64-static.zip"
    else
        # Fallback to i386 for any other architecture
        file="edcre-v1.1.0-linux-i386-static.zip"
    fi
    platform="lin"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

toolDir=./tools/bin/$platform/edcre
url="https://github.com/alex-free/edcre/releases/download/v1.1.0/$file"
target="$toolDir/$file"

if [ ! -d "$toolDir" ]; then
  mkdir -p $toolDir
else
  if [ "$(ls -A $toolDir)" ]; then
    echo "EDCRE directory is not empty! Proceeding will clear all of its contents."
    read -r -p "Are you sure? [y/N] " response

    case "$response" in
    [yY][eE][sS]|[yY]) 
        rm -rf $toolDir/*
        ;;
    *)
        exit
        ;;
    esac
  fi
fi

# Ensure parent directories exist
mkdir -p $(dirname $toolDir)
cd $toolDir
wget $url # -q --show-progress

if [ ! -f $file ]; then
  echo "Installation failed!";
  exit
fi

printf "Extracting";
# Create a temp directory for extraction
mkdir -p temp_extract
if ! command -v pv 2>&1 >/dev/null
then
  unzip -q $file -d temp_extract
  printf "."
else
  unzip $file -d temp_extract | pv -l >/dev/null
fi

# Move contents from subdirectory to current directory
mv temp_extract/*/* . 2>/dev/null || mv temp_extract/* .
rmdir temp_extract/* 2>/dev/null
rmdir temp_extract

printf "\nCleaning up...\n";
rm -f $file

printf "\nSetting permissions\n";
chmod -R +x .
cd ../../..