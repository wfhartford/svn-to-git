#!/bin/bash

backupShare=//fs/SVN_Backups
credentials=$PWD/.cifs-auth

mkdir backup 2> /dev/null || true
sudo mount -t cifs -ocredentials=$credentials -overs=2.0 $backupShare backup
