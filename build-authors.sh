#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -ne 1 ]; then
  echo "Requires one argument, the NS produced user dump from AD"
  exit 1
else
  adUsers=$1
fi

rm -rf authors-working
mkdir authors-working

for repo in work/svn/repos/*
do
  name=$(basename $repo)
  url="file://$PWD/$repo"
  java -jar svn-migration-scripts.jar authors $url | \
      sed 's/ZEPOWER\\//g' | \
      awk '{print tolower($1)}' | \
      sort | uniq > authors-working/authors.$name.txt
done

allAuthors=authors-working/author-user-names.txt
sort authors-working/authors.*.txt | uniq > $allAuthors

allUsers=authors-working/all-users.csv
tail -n +2 ALLADUsers_201711031005.csv | awk -F , '{
if ($6 && $3)
  print tolower($4)","$3" <"tolower($6)">";
else if ($3)
  print tolower($4)","$3" <"tolower($4)"@ze.com>";
else if ($6)
  print tolower($4)","$4" <"tolower($6)">";
else 
  print tolower($4)","$4" <"tolower($4)"@ze.com>";
}' > $allUsers

(mkdir work || rm work/authors.txt || true) 2> /dev/null
while IFS= read -r line; do
  userInfo=$(grep "^$line," $allUsers | awk -F , '{print $2}' || echo "$line <$line@ze.com>")
  echo "$line = $userInfo" >> work/authors.txt
done < $allAuthors
