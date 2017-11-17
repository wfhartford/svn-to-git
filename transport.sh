#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SVN=$1
RULES_FILE=$2
TIME=$(date -u +%Y%m%d%H%M%S)
repos=()

function listRepos {
  dir=$(dirname $1)
  for include in $(grep include $1 | awk '{print $2}' || true)
  do
    listRepos $dir/$include
  done
  repos+=($(grep "create repository" $1 | awk '{print $3}' || true))
}

listRepos $RULES_FILE
unique_repos=($(tr ' ' '\n' <<< "${repos[@]}" | sort -u))
#echo "Found Repositories:"
#for repo in "${unique_repos[@]}"
#do
#  echo " - $repo"
#done
#exit 0

if [ ! -d logs ]
then
 mkdir logs
fi

echo "Transporting SVN repo $SVN"
eval "./svn-all-fast-export --identity-map authors.txt --add-metadata --add-metadata-notes --stats --rules $RULES_FILE $SVN" \
    > logs/$(basename $SVN)-$TIME-transport.log \
    2> logs/$(basename $SVN)-$TIME-transport.err
for repo in "${unique_repos[@]}"
do
  echo "Tidying GIT repo $repo; currently $(du -hs $repo | awk {'print $1'})"
  (
    cd $repo
    git tag -l | (grep backups/ || true) | xargs -r git tag -d
    git gc
    git repack -a -d -f
  ) > logs/$(basename $repo)-$TIME-tidy.log \
   2> logs/$(basename $repo)-$TIME-tidy.err
  echo "Tidied GIT repo $repo to $(du -hs $repo | awk {'print $1'})"
done
