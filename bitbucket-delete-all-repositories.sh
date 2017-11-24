#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./bitbucket-conf.sh

for repoDir in repo/*
do
  repoName=$(basename $repoDir)
  echo "Deleting repository named $repoName"
  curl -s -XDELETE -H "Authorization: Bearer $token" $base/rest/api/1.0/projects/$project/repos/$repoName
  echo
done

echo "All repositories have been scheduled for deletion."
echo "Wait for them to disappear before uploading."
