#!/usr/bin/env bash

function git_run() {
  local repo_dir="${1}"
  shift

  git -C "${repo_dir}" "$@"
}
