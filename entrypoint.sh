#!/bin/bash

set -ex

echo "${INPUT_TEMPLATE}" >template.txt
github-search-templater -t template.txt "${INPUT_QUERY}" > generated.md

curl \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H 'Accept: application/vnd.github.v3.raw' \
  -L https://api.github.com/repos/${INPUT_REPO}/contents/${INPUT_FILEPATH} \
  > got.md

diff -B generated.md got.md

case $? in
  0)
    exit 0
    ;;
  2)
    echo "diff command failed" >&2
    exit 1
    ;;
esac

git config --global user.name "${INPUT_AUTHOR}"
git config --global user.email "${INPUT_EMAIL}"

git config --get user.name
git config --get user.email

title="Update ${INPUT_FILEPATH}"
branch="github-search-templater/update-file"
body=$(cat <<__BODY__
## WHAT
Update some docs
## WHY
Some updates are detected by https://github.com/b4b4r07/github-search-templater
__BODY__
)
body="${INPUT_PRBODY:-${body}}"

git checkout -b "${branch}"
cp -f "generated.md" "${INPUT_FILEPATH}"
git add "${INPUT_FILEPATH}"
git commit -m "${title}"
git push origin "${branch}"

data=$(jq -n \
  --arg title "${title}" \
  --arg body "${body}" \
  --arg head "${branch}" \
  --arg base "master" \
  '{title: $title, body: $body, head: $head, base: $base}'
)

curl --silent --request POST \
  --url https://api.github.com/repos/${INPUT_REPO}/pulls \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --header 'content-type: application/json' \
  --data "${data}"

git checkout master
