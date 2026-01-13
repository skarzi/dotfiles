#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

nightlight temp 100
nightlight schedule start
