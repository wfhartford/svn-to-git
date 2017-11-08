#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -ne 1 ]; then
  echo "Requires one argument, the user dump CSV file"
  exit 1
else
  adUsers=$1
fi

domain=ZEPOWER

rm -rf work/authors
mkdir -p work/authors

for repo in work/svn/repos/*
do
  name=$(basename $repo)
  url="file://$PWD/$repo"
  java -jar svn-migration-scripts.jar authors $url | \
      sed "s/$domain\\\\//g" | \
      awk '{print $1}' | \
      sort | uniq > work/authors/authors.$name.txt
done

allAuthors=work/authors/author-user-names.txt
sort work/authors/authors.*.txt | uniq > $allAuthors

allUsers=work/authors/all-users.csv
tail -n +2 $adUsers | awk -F , '{
if ($6 && $3)
  print tolower($4)","$3" <"tolower($6)">";
else if ($3)
  print tolower($4)","$3" <"tolower($4)"@ze.com>";
else if ($6)
  print tolower($4)","tolower($4)" <"tolower($6)">";
else 
  print tolower($4)","tolower($4)" <"tolower($4)"@ze.com>";
}' > $allUsers

(rm work/authors.txt || true) 2> /dev/null
while IFS= read -r line; do
  userInfo=$(grep -i "^$line," $allUsers | awk -F , '{print $2}' || echo "$line <$line@ze.com>" | tr '[:upper:]' '[:lower:]')
  echo "$line = $userInfo" >> work/authors/authors-no-domain.txt
done < $allAuthors

cp work/authors/authors-no-domain.txt work/authors.txt
sed -e "s/^/$domain\\\\/" work/authors/authors-no-domain.txt >> work/authors.txt
