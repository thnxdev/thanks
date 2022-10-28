## thanks.dev CLI script

### Purpose
This shell script can be used to upload a repositories manifest files to thanks.dev as part of a CI/CD pipeline

### Prerequisites
- `curl`
- `jq`
- `base64`

### Instructions
This script scans the current working directory for manifest files. It should be run as follows:
```
Usage: INGEST_KEY=<ingest-key> sh -c "$(curl -fsSL https://raw.githubusercontent.com/thnxdev/thanks/master/thanks.sh) [options]"
    options:
        --type (go.list,pom.xml,package.json)     [required]
        --entity <entity>                         [required]
        --repo <repo>                             [required]
        --own-module <module>
        --own-scope <scope>
```
