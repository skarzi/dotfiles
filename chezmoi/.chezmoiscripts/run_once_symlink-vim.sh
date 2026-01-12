#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

ln -sfn "${HOME}/dotfiles/.vim" "${HOME}/.vim"
ln -sfn "${HOME}/dotfiles/.vim/.vimrc" "${HOME}/.vimrc"
