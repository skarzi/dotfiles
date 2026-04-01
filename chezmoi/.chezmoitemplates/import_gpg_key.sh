# shellcheck shell=bash

# Import a GPG private key from stdin and set ultimate trust level.
# Globals:
#   None
# Arguments:
#   ${1}: Email address associated with the GPG key.
# Outputs:
#   Status messages written to STDOUT.
# Returns:
#   0 on success or if the key is already imported.
#   1 if the fingerprint cannot be retrieved after import.
import_gpg_key() {
  local key_email="${1}"
  local fingerprint

  # Idempotency check: see if the secret key is already imported.
  if gpg --list-secret-keys "${key_email}" > /dev/null 2>&1; then
    echo "GPG key for ${key_email} is already imported. Skipping."
    cat > /dev/null
    return 0
  fi

  echo "Importing GPG key for ${key_email}..."
  # Securely import the private key from stdin.
  gpg --batch --import
  # Extract the fingerprint using the '--with-colons' output format.
  fingerprint="$(gpg --list-keys --with-colons "${key_email}" | awk -F: '/^fpr:/ { print $10 }' | head -n1)"

  if [[ -n "${fingerprint}" ]]; then
    echo "Setting ultimate trust for key ${fingerprint}..."
    # '6' is the trust level for 'Ultimate'.
    echo "${fingerprint}:6:" | gpg --import-ownertrust
    echo "✅ GPG key for ${key_email} successfully imported and trusted."
  else
    echo "❌ Failed to retrieve the GPG fingerprint for ${key_email}. Trust level not set."
    return 1
  fi
}
