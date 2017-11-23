#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source=local-backup
if [ ! -e $source ]
then
  echo "First create a $source directory or symlink containing hotcopy backups"
  exit 1
fi

dest=svn
if [ ! -e $dest ]
then
  echo "First create a $dest directory or symlink to contain extracted repositories"
  exit 1
fi

limit=$(nproc)
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
  destination=$dest/$name
  if [ -d $destination ]
  then
    echo "Skipping $file since $destination already exists"
  else
    mkdir $destination
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
