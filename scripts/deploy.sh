#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${__dir}/libs/logs.sh"
source "${__dir}/libs/git.sh"

IMAGE_TAG=${1:-"latest"}

K8S_REPO="git@github.com:K-Phoen/homelab.git"
BLOG_VALUES_FILE="k8s/blog/values.yaml"

DRY_RUN=${DRY_RUN:-"yes"} # Some kind of fail-safe to ensure that we're only pushing something when we mean it.
CLEANUP_WORKSPACE=${CLEANUP_WORKSPACE:-"yes"} # Should the workspace be deleted after the script runs?
WORKSPACE_PATH=${WORKSPACE_PATH:-'./workspace'}

function run_when_safe() {
  local command=${1}
  shift

  if [ "${DRY_RUN}" == "no" ]; then
    ${command} "$@"
  else
    warning "Dry run enabled: skipping execution of \"${command} $*\""
    info "Run this script with DRY_RUN=no to disable dry-run mode."
  fi
}

#################
### Usage ###
#################

# LOG_LEVEL=7 ./scripts/deploy.sh 1de9a45

############
### Main ###
############

k8s_repo_workspace="${WORKSPACE_PATH}/k8s-repo"

function cleanup() {
  debug "Cleaning up workspace"
  rm -rf "${WORKSPACE_PATH}"
}
if [ "${CLEANUP_WORKSPACE}" == "yes" ]; then
  trap cleanup EXIT # run the cleanup() function on exit
fi

if [ "${DRY_RUN}" == "no" ]; then
  warning "Dry-run is OFF."
else
  notice "Dry-run is ON."
fi

# Just in case there are leftovers from a previous run.
rm -rf "${WORKSPACE_PATH}"

info "Cloning ${K8S_REPO} into ${k8s_repo_workspace}"
git clone --depth 1 "${K8S_REPO}" "${k8s_repo_workspace}"

debug "Updating ${BLOG_VALUES_FILE}"
yq -i ".blog.tag = \"${IMAGE_TAG}\"" "${k8s_repo_workspace}/${BLOG_VALUES_FILE}"

debug "Adding changes to git staging area"
git_run "${k8s_repo_workspace}" add .

debug "Committing change"
git_run "${k8s_repo_workspace}" commit -m "Automated blog release"

info "Pushing change"
run_when_safe git_run "${k8s_repo_workspace}" push origin main
