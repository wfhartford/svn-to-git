#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ ! ${!JAVA_6_HOME[@]} ]
then
  echo "Set the JAVA_6_HOME environment variable to the location of a Java 6 installation"
  exit 1
fi

# Build atlassian's tools jar, which we use to create the authors mapping.
rm -rf work/svn-migration-scripts svn-migration-scripts.jar
git clone git@bitbucket.org:pcompieta/svn-migration-scripts.git work/svn-migration-scripts
(cd work/svn-migration-scripts && sbt -java-home $JAVA_6_HOME proguard)
ln -s work/svn-migration-scripts/target/svn-migration-scripts.jar .

# Build the svn-all-fast-export tool, which we use for the actual conversion.
rm -rf work/svn2git svn-all-fast-export
git clone git@github.com:svn-all-fast-export/svn2git.git work/svn2git
(cd work/svn2git && qmake && make)
ln -s work/svn2git/svn-all-fast-export .
