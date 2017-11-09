#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source=local-backup
if [ ! -e $source ]
then
  echo "First create a local-backup directory or symlink containing hotcopy backups"
  exit 1
fi

limit=8
function limitBg {
  while [ $(jobs | wc -l) -ge $limit ]
  do
    sleep 5
  done
}

for backup in $source/*
do
  file=$(basename $backup)
  name=${file:0:-8}
  destination=work/svn/repos/$name
  if [ ! -d $destination ]
  then
      mkdir -p $destination
      limitBg
      echo "Extracting $file to $destination"
      (
        tar xf $backup -C $destination
        rm $destination/hooks/* $destination/locks/* $destination/conf/*
        (
          svnadmin lslocks $destination | \
              grep -B2 Owner | \
              grep Path | \
              sed "s/Path: \///" | \
              tr "\n" "\0" | \
              xargs -r0 svnadmin rmlocks $destination > /dev/null
        ) || true
        chmod -R -w $destination
        echo "Finished extracting $file"
      ) &
  fi
done

echo "Waiting for extraction to complete"
wait
