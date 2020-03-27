#!/bin/sh

set -ex

if [ -n "$github_personal_access_token" ]; then
  header_text="Authorization: token $github_personal_access_token"
fi

curl -sS -H "$header_text" https://api.github.com/repos/hashicorp/terraform/releases/latest \
  > /curlOutput.txt
tfVersion=$(cat /curlOutput.txt | jq -r '.tag_name' | tr -d 'v' )

set +x

if [ "$tfVersion" = "null" ]; then
  >&2 echo "ERROR: could not get latest Terraform version from Github.com"
  >&2 echo "ERROR: curl output:
$(cat /curlOutput.txt)"
  exit 1
fi

echo $tfVersion
