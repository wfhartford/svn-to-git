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
  echo "Authors file must be created prior to repository cloning"
  exit 2
fi

if [ ! -d work/git ]
then
  mkdir work/git
fi
if [ ! -d work/git-bare ]
then
  mkdir work/git-bare
fi
if [ ! -d work/logs ]
then
  mkdir work/logs
fi

defaultLayout=$(grep "^,," $layoutsFile)

originalGcValue=$(git config --global --get gc.auto || echo 'unset')
git config --global gc.auto 0
function cleanup {
  if [ 'unset' == $originalGcValue ]
  then 
    git config --global --unset gc.auto
  else
    git config --global gc.auto $originalGcValue
  fi
}
trap cleanup EXIT

time=$(date -u +%Y%m%d%H%M%S)

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
        if [ -d work/git/$gitRepo ]
        then
          rm -rf work/git/$gitRepo
        fi
        if [ -L work/git-bare/$gitRepo ]
        then
          rm work/git-bare/$gitRepo
        fi
        eval git svn clone --authors-file=work/authors.txt $arguments $url work/git/$gitRepo \
            > work/logs/$gitRepo-git-svn-clone-$time.log \
            2> work/logs/$gitRepo-git-svn-clone-$time.err
        (
          cd work/git/$gitRepo
          if java -Dfile.encoding=utf-8 -jar ../../../svn-migration-scripts.jar clean-git --force --prefix=origin/
          then
            echo "Unexpected clean-git exit code of 0" > 2
            exit 1
          else
            exitCode=$?
            if [ ! $exitCode -eq 1 ]
            then
              echo "Unexpected clean-git exit code of $exitCode" > 2
              exit 1
            fi
          fi
        ) > work/logs/$gitRepo-clean-git-$time.log
        ln -s ../git/$gitRepo/.git work/git-bare/$gitRepo
      fi
    fi
  done
done
