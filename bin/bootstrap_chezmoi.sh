#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

# TODO(skarzi): Add code to bootstrap `chezmoi` on linux.
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Not running on macOS. Skipping bootstrap."
  exit 0
fi

echo "Checking Homebrew..."
if ! command -v brew > /dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  _URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  bash -c "$(curl --fail --silent --show-error --location "${_URL}")"
else
  echo "Homebrew already installed."
fi

echo "Installing prerequisites for chezmoi..."
# Install `rage` and `pass-cli` to resolve circular dependencies during template rendering.
brew install chezmoi rage protonpass/tap/pass-cli

# Setup `rage` to decrypt data on initial `chezmoi apply` call.
_AGE_KEYS_PATH="${HOME}/.config/age/keys.txt"
if [[ ! -f "${_AGE_KEYS_PATH}" ]]; then
  echo "Downloading 'age' keys from Proton Pass..."
  if ! pass-cli info > /dev/null 2>&1; then
    echo "Please login to Proton Pass:"
    pass-cli login
  fi
  mkdir -p "$(dirname "${_AGE_KEYS_PATH}")"
  chmod 700 "$(dirname "${_AGE_KEYS_PATH}")"
  pass-cli item attachment download \
    --share-id "uwsLkR4MR2Dt_TGKcyhAGkKIHma5Bxg4dGz9I5dVNvQaWMv62yUsCLTk-YLYh3NdBwUkZTih3x3Hs6J3y8Im1w==" \
    --item-id "7ITPvN0q-L3YIMrCyaIDqcL4mEdYW-jw5xz4nL5lQ8d4GFFk4SzuMGsIA_GkBCqwN2u0D_78XXjax_AUIMvoag==" \
    --attachment-id "G7xOj0tGgZtTehY-tfI5YEwI8LCfr1yt-dfkmNqSAQ3zpYRXu2l-xmiGP3MaOZY3GTWV2APF-CgD540m3aw2aw==" \
    --output "${_AGE_KEYS_PATH}"
  chmod 600 "${_AGE_KEYS_PATH}"
fi

echo "Bootstrap complete. You can now run 'chezmoi init --apply --verbose'"
