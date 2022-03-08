#!/bin/sh
#
# This script should be run via curl:
#   INGEST_KEY=_ingest_token_ ENTITIES=_entity_paths_ REPOSITORY=_repo_name_ sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh)"
#
# Respects the following environment variables:
#   - `ENABLE_GOLIST                - defaults to 'yes', set to 'no' if go.list files are to be ignored
#   - `ENABLE_JS                    - defaults to 'yes', set to 'no' if package.json, package-lock.json, yarn.lock files are to be ignored
#   - `ENABLE_POMXML                - defaults to 'yes', set to 'no' if pom.xml files are to be ignored
#
# You can also pass some arguments to the script to set some of these options:
#   - `--disable-golist has the same behavior as setting `ENABLE_GOLIST to 'no'
#   - `--disable-js has the same behavior as setting `ENABLE_JS to 'no'
#   - `--disable-pomxml has the same behavior as setting `ENABLE_POMXML to 'no'
set -e

[[ -z "$INGEST_KEY" ]] && echo "INGEST_KEY not set" && exit 1
[[ -z "$ENTITIES" ]] && echo "ENTITIES not set" && exit 1
[[ -z "$REPOSITORY" ]] && echo "REPOSITORY not set" && exit 1

# Default settings
API_URL=${API_URL:-https://api.thanks.dev/v1/ingest}
ENABLE_GOLIST=${ENABLE_GOLIST:-yes}
ENABLE_JS=${ENABLE_JS:-yes}
ENABLE_POMXML=${ENABLE_POMXML:-yes}


upload() {
  echo "processing $@"
  data=""
  while [[ $# -gt 0 ]]; do
    fc=$(cat "$1" | base64)
    if [[ ! -z "$data" ]]; then
      data="${data}#"
    fi
    data="${data}${1}:${fc}"
    shift
  done
  payload=$(jq \
    -n \
    -c \
    --arg entities "$ENTITIES" \
    --arg repo "$REPOSITORY" \
    --arg data "$data" \
    '{version:2,entities:($entities | split(",")),repository:$repo,data:($data | split("#") | map(split(":") | {path:.[0],content:.[1]}))}' \
  )
  curl \
    -fsSL \
    -XPOST \
    -H "content-type: application/json" \
    -H "INGEST-KEY: $INGEST_KEY" \
    "$API_URL" \
    -d "$payload"
}

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --disable-golist) ENABLE_GOLIST=no ;;
      --disable-pomxml) ENABLE_POMXML=no ;;
    esac
    shift
  done

  if [[ "$ENABLE_GOLIST" = "yes" ]] && [[ -e "go.list" ]]; then
    upload "go.list"
  fi

  if [[ "$ENABLE_JS" = "yes" ]]; then
    if [[ -e "package.json" ]] && [[ -e "package-lock.json" ]]; then
      upload "package.json" "package-lock.json"
    elif [[ -e "package.json" ]] && [[ -e "yarn.lock" ]]; then
      upload "package.json" "yarn.lock"
    elif [[ -e "package.json" ]]; then
      upload "package.json"
    fi
  fi

  if [[ "$ENABLE_POMXML" = "yes" ]] && [[ -e "pom.xml" ]]; then
    upload "pom.xml"
  fi
}

main "$@"
