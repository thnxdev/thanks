#!/bin/sh
set -e

[[ -z "$INGEST_KEY" ]] && echo "INGEST_KEY not set" && exit 1

# Default settings
API_URL=${API_URL:-https://api.thanks.dev/v1/ingest}
ENTITY=""
REPO=""
FILE_PATH=""
OWN_MODULES=""
OWN_SCOPES=""

print_help() {
  echo "THANKS.DEV CLI manifest uploader."
  echo
  echo "Usage: INGEST_KEY=<ingest-key> $0 [options]"
  echo "    options:"
  echo "        --type (gradle.dependencies,package.json) [required]"
  echo "        --entity <entity>                         [required]"
  echo "        --repo <repo>                             [required]"
  echo "        --path <path>                             [required]"
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
      --path)
        FILE_PATH="$2"
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

  [[ -z "$TYPE" ]] && print_help && exit 1
  [[ -z "$ENTITY" ]] && print_help && exit 1
  [[ -z "$REPO" ]] && print_help && exit 1
  [[ -z "$FILE_PATH" ]] && print_help && exit 1
  [[ ! -f "$FILE_PATH" ]] && print_help && exit 1

  payload=$(jq \
    -n \
    -c \
    --rawfile content "$FILE_PATH" \
    --arg entity "$ENTITY" \
    --arg repo "$REPO" \
    --arg own "$OWN_MODULES" \
    --arg type "$TYPE" \
    --arg path "$FILE_PATH" \
    '{version:2,entity:$entity,repo:$repo,type:$type,ownModules:($own | split(",")),path:$path,content:($content | @base64)}' \
  )

  tmpfile=$(mktemp "${TMPDIR:-/tmp}/_td.XXXXXX")
  echo "$payload" > $tmpfile

  curl \
    -fsSL \
    -XPOST \
    -H "content-type: application/json" \
    -H "INGEST-KEY: $INGEST_KEY" \
    "$API_URL" \
    -d "@$tmpfile"
  rm "$tmpfile"
}

main "$@"
