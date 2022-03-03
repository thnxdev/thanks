#!/bin/sh
#
# This script should be run via curl:
#   INGEST_KEY=_ingest_token_ ENTITIES=_entity_paths_ REPOSITORY=_repo_name_ sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh)"
#
# Respects the following environment variables:
#   ENABLE_GOLIST               - defaults to yes, set to no if go.list files are to be ignored
#   ENABLE_POMXML               - defaults to yes, set to no if pom.xml files are to be ignored
#
# You can also pass some arguments to the script to set some of these options:
#   --disable-packagelock-json has the same behavior as setting ENABLE_PACKAGELOCK_JSON to 'no'
#   --disable-golist has the same behavior as setting ENABLE_GOLIST to 'no'
#   --disable-pomxml has the same behavior as setting ENABLE_POMXML to 'no'
#
set -e

[[ -z "$INGEST_KEY" ]] && echo "INGEST_KEY not set" && exit 1
[[ -z "$ENTITIES" ]] && echo "ENTITIES not set" && exit 1
[[ -z "$REPOSITORY" ]] && echo "REPOSITORY not set" && exit 1

# Default settings
API_URL=${API_URL:-https://api.thanks.dev/v1/ingest}
ENABLE_PACKAGELOCK_JSON=${ENABLE_PACKAGELOCK_JSON:-yes}
ENABLE_GOLIST=${ENABLE_GOLIST:-yes}
ENABLE_POMXML=${ENABLE_POMXML:-yes}


upload() {
  fn="$1"
  echo "processing $fn"
  content=$(cat "$fn" | base64)
  payload=$(jq \
    -n \
    -c \
    --arg entities "$ENTITIES" \
    --arg repo "$REPOSITORY" \
    --arg path "$fn" \
    --arg content "$content" \
    '{version:1,entities:($entities | split(",")),repository:$repo,path:$path,content:$content}' \
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
      --disable-packagelock-json) ENABLE_PACKAGELOCK_JSON=no ;;
      --disable-golist) ENABLE_GOLIST=no ;;
      --disable-pomxml) ENABLE_POMXML=no ;;
    esac
    shift
  done

  if [[ "$ENABLE_PACKAGELOCK_JSON" = "yes" ]] && [[ -e "package-lock.json" ]]; then
    upload "package-lock.json"
  fi

  if [[ "$ENABLE_GOLIST" = "yes" ]] && [[ -e "go.list" ]]; then
    upload "go.list"
  fi

  if [[ "$ENABLE_POMXML" = "yes" ]] && [[ -e "pom.xml" ]]; then
    upload "pom.xml"
  fi
}

main "$@"
