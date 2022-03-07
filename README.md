## thanks.dev CLI script

### Purpose
This shell script can be used to upload a repositories manifest files to thanks.dev as part of a CI/CD pipeline

### Prerequisites
- `find`
- `curl`
- `jq`
- `base64`

### Instructions
This script scans the current working directory for manifest files. It should be run as follows:
```
INGEST_KEY=<ingest_token> ENTITIES=<entity_paths> REPOSITORY=<repo_name> sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh)"
```

Respects the following environment variables:
  - `ENABLE_GOLIST                - defaults to 'yes', set to 'no' if go.list files are to be ignored
  - `ENABLE_POMXML                - defaults to 'yes', set to 'no' if pom.xml files are to be ignored

You can also pass some arguments to the script to set some of these options:
  - `--disable-golist has the same behavior as setting `ENABLE_GOLIST to 'no'
  - `--disable-pomxml has the same behavior as setting `ENABLE_POMXML to 'no'
