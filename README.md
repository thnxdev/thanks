## thanks.dev CLI script

### Purpose
This shell script can be used to upload a repositories manifest files to thanks.dev as part of a CI/CD pipeline

### Prerequisites
- `find`
- `curl`
- `jq`
- `base64`

### Instructions

This script should be run via curl:
```
INGEST_KEY=<ingest_token> ENTITY=<entity_name> REPOSITORY=<repo_name> sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh)"
```

Respects the following environment variables:
  - `ENABLE_JS`     - defaults to yes, set to no if package.json files are to be ignored
  - `ENABLE_RS`     - defaults to yes, set to no if cargo.toml files are to be ignored
  - `ENABLE_GO`     - defaults to yes, set to no if go.mod files are to be ignored

You can also pass some arguments to the script to set some of these options:
  - `--disable-js` has the same behavior as setting `ENABLE_JS` to 'no'
  - `--disable-rs` has the same behavior as setting `ENABLE_RS` to 'no'
  - `--disable-go` has the same behavior as setting `ENABLE_GO` to 'no'
