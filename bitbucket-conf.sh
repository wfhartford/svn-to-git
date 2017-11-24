#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

export token=$(<.bitbucket-token)
export base=http://zema-dev-01:7990
export project=IMP
