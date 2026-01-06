#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

ln -sfn "${HOME}/dotfiles/nvim" "${HOME}/.config/nvim"
