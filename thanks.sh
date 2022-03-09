#!/bin/sh
set -e

[[ -z "$INGEST_KEY" ]] && echo "INGEST_KEY not set" && exit 1

# Default settings
API_URL=${API_URL:-https://api.thanks.dev/v1/ingest}
ENTITY=""
REPO=""
OWN_MODULES=""
OWN_SCOPES=""


upload() {
  curl \
    -fsSL \
    -XPOST \
    -H "content-type: application/json" \
    -H "INGEST-KEY: $INGEST_KEY" \
    "$API_URL" \
    -d "$1"
}

process_go_list() {
  data=$(cat go.list | base64)
  payload=$(jq \
    -n \
    -c \
    --arg entity "$ENTITY" \
    --arg repo "$REPO" \
    --arg own "$OWN_MODULES" \
    --arg data "$data" \
    '{version:2,entity:$entity,repo:$repo,type:"go.list",ownModules:($own | split(",")),data:$data}' \
  )
  upload "$payload"
}

process_pom() {
  data=$(cat pom.xml | base64)
  payload=$(jq \
    -n \
    -c \
    --arg entity "$ENTITY" \
    --arg repo "$REPO" \
    --arg data "$data" \
    '{version:2,entity:$entity,repo:$repo,type:"pom.xml",data:$data}' \
  )
  upload "$payload"
}

process_js() {
  content=$(cat package.json | base64)
  data="package.json:${content}"
  if [[ -e "package-lock.json" ]]; then
    content=$(cat package-lock.json | base64)
    data="${data}#package-lock.json:${content}"
  elif [[ -e "yarn.lock" ]]; then
    content=$(cat yarn.lock | base64)
    data="${data}#yarn.lock:${content}"
  fi
  payload=$(jq \
    -n \
    -c \
    --arg entity "$ENTITY" \
    --arg repo "$REPO" \
    --arg ownModules "$OWN_MODULES" \
    --arg ownScopes "$OWN_SCOPES" \
    --arg data "$data" \
    '{version:2,entity:$entity,repo:$repo,type:"package.json",ownModules:($ownModules | split(",")),ownScopes:($ownScopes | split(",")),data:($data | split("#") | map(split(":") | {path:.[0],content:.[1]}))}' \
  )
  upload "$payload"
}

print_help() {
  echo "THANKS.DEV CLI manifest uploader."
  echo
  echo "Usage: INGEST_KEY=<ingest-key> $0 [options]"
  echo "    options:"
  echo "        --type (go.list,pom.xml,package.json)     [required]"
  echo "        --entity <entity>                         [required]"
  echo "        --repo <repo>                             [required]"
  echo "        --own-module <module>"
  echo "        --own-scope <scope>"
  echo
}

main() {
  TYPE=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --type)
        TYPE="$2"
        shift
        ;;
      --entity)
        ENTITY="$2"
        shift
        ;;
      --repo)
        REPO="$2"
        shift
        ;;
      --own-module)
        if [[ ! -z "$OWN_MODULES" ]]; then
          OWN_MODULES="${OWN_MODULES},"
        fi
        OWN_MODULES="${OWN_MODULES}${2}"
        shift
        ;;
      --own-scope)
        if [[ ! -z "$OWN_SCOPES" ]]; then
          OWN_SCOPES="${OWN_SCOPES},"
        fi
        OWN_SCOPES="${OWN_SCOPES}${2}"
        shift
        ;;
      --help)
        print_help
        exit 1
        ;;
      *)
        print_help
        exit 1
        ;;
    esac
    shift
  done

  [[ -z "$ENTITY" ]] && print_help && exit 1
  [[ -z "$REPO" ]] && print_help && exit 1

  if [[ "$TYPE" = "go.list" ]] && [[ -e "go.list" ]]; then
    process_go_list
  fi

  if [[ "$TYPE" = "pom.xml" ]] && [[ -e "pom.xml" ]]; then
    process_pom
  fi

  if [[ "$TYPE" = "package.json" ]] && [[ -e "package.json" ]]; then
    process_js
  fi
}

main "$@"
