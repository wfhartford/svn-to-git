#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

TEMP=$(mktemp -d)
function cleanup {      
  rm -rf "$TEMP"
}
trap cleanup EXIT

LATEST=$(ls -d backup/hotcopy/backup.* | sort | tail -n1)
for backup in $LATEST/*
do
  file=$(basename $backup)
  name=${file:0:-8}
  destination=work/svn/repos/$name
  echo "Copying $file to $TEMP"
  cp $backup $TEMP
  mkdir -p $destination
  echo "Extracting $file to $destination"
  (tar xf $TEMP/$file -C $destination && rm $destination/hooks/* $destination/locks/* $destination/conf/* && rm $TEMP/$file && chmod -R -w $destination && echo "Finished extracting $file") &
done

echo "Waiting for extraction to complete"
wait
