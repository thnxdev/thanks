#!/bin/sh
#
# This script should be run via curl:
#   INGEST_KEY=_ingest_token_ ENTITY=_entity_name_ REPOSITORY=_repo_name_ sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh)"
#
# Respects the following environment variables:
#   ENABLE_JS     - defaults to yes, set to no if package.json files are to be ignored
#   ENABLE_RS     - defaults to yes, set to no if cargo.toml files are to be ignored
#   ENABLE_GO     - defaults to yes, set to no if go.mod files are to be ignored
#
# You can also pass some arguments to the script to set some of these options:
#   --disable-js has the same behavior as setting ENABLE_JS to 'no'
#   --disable-rs has the same behavior as setting ENABLE_RS to 'no'
#   --disable-go has the same behavior as setting ENABLE_GO to 'no'
#
set -e

[[ -z "$INGEST_KEY" ]] && echo "INGEST_KEY not set" && exit 1
[[ -z "$ENTITY" ]] && echo "ENTITY not set" && exit 1
[[ -z "$REPOSITORY" ]] && echo "REPOSITORY not set" && exit 1

# Default settings
API_URL=${API_URL:-https://api.thanks.dev/v1/ingest}
ENABLE_JS=${ENABLE_JS:-yes}
ENABLE_RS=${ENABLE_RS:-yes}
ENABLE_GO=${ENABLE_GO:-yes}


upload() {
  fn="$1"
  echo "processing $fn"
  content=$(cat "$fn" | base64)
  payload=$(jq -n \
    --arg entity "$ENTITY" \
    --arg repo "$REPOSITORY" \
    --arg path "$fn" \
    --arg content "$content" \
    '{version:1,entity:$entity,repository:$repo,path:$path,content:$content}' \
  )
  resp=$(curl \
    -sSL \
    -XPOST \
    -H "content-type: application/json" \
    -H "ingest-key: $INGEST_KEY" \
    "$API_URL" \
    -d "$payload" \
  )
  ok=$(echo "$resp" | jq '.ok')
  if [[ ! "$ok" = "true" ]]; then
    echo "ERROR: $resp"
    exit 1
  fi
}

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --disable-js) ENABLE_JS=no ;;
      --disable-rs) ENABLE_RS=no ;;
      --disable-go) ENABLE_GO=no ;;
    esac
    shift
  done

  JS_REGEX='package\.json$'
  RS_REGEX='cargo\.toml$'
  GO_REGEX='go\.mod$'

  find * \
    -type f \
    \( \
      -iname package.json -o \
      -iname cargo.toml -o \
      -iname go.mod \
    \) \
    -not -path 'node_modules/*' \
    -print0 \
  | while read -d $'\0' m
  do
    if [[ ! -z "$m" ]]; then
      # JS
      if [[ "$ENABLE_JS" = "yes" ]] && [[ "$m" =~ $JS_REGEX ]]; then
        upload "$m"
      fi

      # RS
      if [[ "$ENABLE_RS" = "yes" ]] && [[ "$m" =~ $RS_REGEX ]]; then
        upload "$m"
      fi

      # GO
      if [[ "$ENABLE_GO" = "yes" ]] && [[ "$m" =~ $GO_REGEX ]]; then
        upload "$m"
      fi
    fi
  done
}

main "$@"
