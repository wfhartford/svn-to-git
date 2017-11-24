#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -ne 2 ]
then
  echo "Two arguments are required:"
  echo "  $0 <SVN repo location> <rules file>"
  exit 1
fi

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

cp $RULES_FILE $RULES_FILE.tmp
cat >> $RULES_FILE.tmp << EOF
# Must be at end to permit skipping revisions; if you intend for ALL revisions to be handled, this should be removed.
match /
end match
EOF

function cleanup {
  rm $RULES_FILE.tmp
}
trap cleanup EXIT

if [ ! -d logs ]
then
  mkdir logs
fi

echo "Transporting SVN repo $SVN"
eval "./svn-all-fast-export --identity-map authors.txt --add-metadata --add-metadata-notes --stats --rules $RULES_FILE.tmp $SVN" \
    > logs/$(basename $SVN)-$TIME-transport.log \
    2> logs/$(basename $SVN)-$TIME-transport.err
for repo in "${unique_repos[@]}"
do
  echo "Tidying GIT repo $repo; currently $(du -hs $repo | awk {'print $1'})"
  (
    cd $repo
    git reflog expire --expire=now --all
    git gc --prune=now
    git repack -a -d -f
  ) > logs/$(basename $repo)-$TIME-tidy.log \
   2> logs/$(basename $repo)-$TIME-tidy.err
  echo "Tidied GIT repo $repo to $(du -hs $repo | awk {'print $1'})"
done
