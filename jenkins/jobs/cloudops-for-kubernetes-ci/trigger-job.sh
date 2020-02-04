#!/usr/bin/env bash

set -e

error() {
  echo "ERROR: $1"
  exit 1
}

info() {
  echo "INFO: $1"
}

if [[ -z "$JENKINS_URL" ]]; then
  error "\$JENKINS_URL must be set to the URL of a running Jenkins master"
fi

if [[ -z "$JENKINS_ADMIN_USERNAME" ]]; then
  error "\$JENKINS_ADMIN_USERNAME must be set to the username of an admin Jenkins user"
fi

if [[ -z "$JENKINS_API_TOKEN" ]]; then
  error "\$JENKINS_API_TOKEN must be set to the API token of an admin Jenkins user"
fi

if [[ -z "$JENKINS_JOB" ]]; then
  error "\$JENKINS_JOB must be set to the name of the Jenkins job to trigger and wait for"
fi

jenkinsUserAuth="$JENKINS_ADMIN_USERNAME:$JENKINS_API_TOKEN"
# get last build number
info "getting last build number"
lastBuildNumber=$(curl --insecure --location -XPOST -u "$jenkinsUserAuth" -sS "$JENKINS_URL/job/$JENKINS_JOB/lastBuild/buildNumber")

# start the job
info "triggering Jenkins job $JENKINS_JOB"
jobBuildOutput=$(curl --insecure --location -XPOST -u "$jenkinsUserAuth" -sS "$JENKINS_URL/job/$JENKINS_JOB/buildWithParameters$JENKINS_JOB_PARAMETERS")
if [[ -n "$jobBuildOutput" ]]; then
  echo "$jobBuildOutput"
  error "failed triggering Jenkins job $JENKINS_JOB"
fi

# get new build number
timeoutDate=$(( $(date +'%s') + 60 )) # 1 min timeout
triggeredBuildNumber="$lastBuildNumber"

while [[ "$triggeredBuildNumber" == "$lastBuildNumber" ]] ; do

  triggeredBuildNumber=$(curl --insecure --location -XPOST -u "$jenkinsUserAuth" -sS "$JENKINS_URL/job/$JENKINS_JOB/lastBuild/buildNumber")

  if [ "$(date +'%s')" -gt "$timeoutDate" ]; then
    info "last build number of Jenkins job $JENKINS_JOB: $triggeredBuildNumber"
    error "timed out waiting for new build number of Jenkins job $JENKINS_JOB"
  fi

  sleep 5
done

echo "$triggeredBuildNumber" > "${JENKINS_JOB}_lastBuildNumber.txt"
