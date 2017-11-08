#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

rm -rf work/svn-migration-scripts svn-migration-scripts.jar
git clone git@bitbucket.org:pcompieta/svn-migration-scripts.git work/svn-migration-scripts
(cd work/svn-migration-scripts && sbt -java-home $JAVA_6_HOME proguard)
ln -s work/svn-migration-scripts/target/svn-migration-scripts.jar .
