#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ ! -d logs ]
then
  mkdir logs
fi

limit=$(nproc)
function limitBg {
  while [ $(jobs | wc -l) -ge $limit ]
  do
    sleep 5
  done
}

for rulesFile in rules/*/main.rules
do
  svnPath=svn/$(basename $(dirname $rulesFile))
  if [ -d $svnPath ]
  then
    limitBg
    (
        ./transport.sh $svnPath $rulesFile
        echo "Transport of $svnPath compete"
    ) &
  else
    echo "No directory where SVN repository is expected: $svnPath"
  fi
done

echo "Waiting for transport operations to complete"
wait
