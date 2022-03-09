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
Usage: INGEST_KEY=<ingest-key> /Users/nehzata/Documents/td/thanks/thanks.sh [options]
    options:
        --type (go.list,pom.xml,package.json)     [required]
        --entity <entity>                         [required]
        --repo <repo>                             [required]
        --own-module <module>
        --own-scope <scope>
```
