#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -ne 1 ]; then
  echo "Requires one argument, the layout arguments file"
  exit 1
else
  layoutsFile=$1
fi

if [ ! -e work/authors.txt ]
then
  echo "Authors file must be created prior to repository clonging"
  exit 2
fi

rm -rf work/git
mkdir work/git

defaultLayout=$(grep "^,," $layoutsFile)
echo "Default Layout: $defaultLayout"

for repo in work/svn/repos/*
do
  name=$(basename $repo)
  url="file://$PWD/$repo"
  layouts=($(grep "^$name," $layoutsFile || true))
  if [ ${#layouts[@]} -eq 0 ]
  then
    layouts=($defaultLayout)
  fi
  for line in "${layouts[@]}"
  do
    if [[ "$line" =~ ^[^,]*,([^,]*),(.*)$ ]]
    then
      gitRepo=${BASH_REMATCH[1]:-$name}
      arguments=${BASH_REMATCH[2]}
      if [ ! -z "$arguments" ]
      then
        echo "Cloning SVN repo $name to Git repo $gitRepo with arguments $arguments"
        eval git svn clone --authors-file=work/authors.txt $arguments $url work/git/$gitRepo
      fi
    fi
  done
done
