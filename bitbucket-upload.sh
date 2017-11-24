#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

time=$(date -u +%Y%m%d%H%M%S)
token=$(<.bitbucket-token)
base=http://zema-dev-01:7990
project=IMP

limit=$(nproc)
function limitBg {
  while [ $(jobs | wc -l) -ge $limit ]
  do
    sleep 5
  done
}

for repoDir in repo/*
do
  repoName=$(basename $repoDir)
  limitBg
  echo "Uploading $repoName"
  (
    (
      curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
           -d "{\"name\":\"$repoName\",\"scmId\":\"git\",\"forkable\":true}" \
           $base/rest/api/1.0/projects/$project/repos
      cd $repoDir
      git remote add bitbucket ssh://git@zema-dev-01:7999/imp/$repoName.git
      git push --all bitbucket
      git push --tags bitbucket
    ) > logs/$repoName-$time-upload.log \
     2> logs/$repoName-$time-upload.err
  ) &
done

echo "Waiting for bitbucket upload to complete"
wait
