#!/usr/bin/env bash

error() {
  echo "ERROR: $1"
  exit 1
}

info() {
  echo "INFO: $1"
}

debug() {
  echo "DEBUG: $1"
}

if [[ -z "$JENKINS_URL" ]]; then
  error "\$JENKINS_URL must be set to the URL of a running Jenkins master"
fi

if [[ -z "$JENKINS_ADMIN_USERNAME" ]]; then
  error "\$JENKINS_ADMIN_USERNAME must be set to the username of an admin Jenkins user"
fi

if [[ -z "$JENKINS_ADMIN_PASSWORD" ]]; then
  error "\$JENKINS_ADMIN_PASSWORD must be set to the password of an admin Jenkins user"
fi

if [[ -z "$JENKINS_JOB" ]]; then
  error "\$JENKINS_JOB must be set to the name of the Jenkins job to trigger and wait for"
fi

if [[ -z "$JENKINS_JOB_TIMEOUT" ]]; then
  error "\$JENKINS_JOB_TIMEOUT must be set to the number of seconds after which to timeout waiting for the Jenkins job to finish successfully"
fi

if [[ -z "$JENKINS_BUILD_NUMBER" ]]; then
  error "\$JENKINS_BUILD_NUMBER must be set to the build number which to wait for"
fi

jenkinsUserAuth="$JENKINS_ADMIN_USERNAME:$JENKINS_ADMIN_PASSWORD"

sleepCycle=$(( $JENKINS_JOB_TIMEOUT / 60 ))
if [[ $sleepCycle -lt 5 ]]; then
  sleepCycle=5
elif [[ $sleepCycle -gt 30 ]]; then
  sleepCycle=30
fi
info "using a sleep cycle of $sleepCycle seconds"

timeoutDate=$(( $(date +'%s') + $JENKINS_JOB_TIMEOUT ))

isJobDone="false"
logPosition="0"
while [ "$isJobDone" = "false" ]; do

  # ( num seconds left / 60 seconds ) + 1 minute
  waitTimeLeft=$(( $(( $(( $timeoutDate - $(date +'%s') )) / 60 )) + 1 ))
  info "waiting up to $waitTimeLeft minutes for Jenkins job $JENKINS_JOB finish..."

  # Pull logs from remote jenkins job and display them if they are new
  newLogs=$(curl --insecure --location -D headers.txt -u "$jenkinsUserAuth" "$JENKINS_URL/job/$JENKINS_JOB/$JENKINS_BUILD_NUMBER/logText/progressiveText?start=${logPosition}" -sS) > log-errors.txt
  responseCode="$(cat headers.txt | tr -d '\r' | grep -E '^HTTP/[0-9.]+[[:space:]]+[0-9]{3}' | awk '{ print $2 }')"
  if [[ "${responseCode}" =~ 2[0-9][0-9] ]]; then
    info "new job logs:"
    echo "${newLogs}" | sed 's/^/        /g'
    logPosition=$(cat headers.txt | tr -d '\r' | grep -i -E '^X-Text-Size:[[:space:]]+' | awk '{ print $2 }')
  else
    info "logs for job not yet available"
    if [ -s log-errors.txt ]; then
      info "log errors:"
      cat log-errors.txt
    fi
  fi

  # Check if the job has succeeded or failed
  jobState=$(curl --insecure --location -D job-state-headers.txt -u "$jenkinsUserAuth" "$JENKINS_URL/job/$JENKINS_JOB/$JENKINS_BUILD_NUMBER/api/json" -sS) 2> job-state-curl-errors.txt
  if [ "$(echo "${jobState}" | jq -r '.result')" == "SUCCESS" ]; then
    isJobDone="true"
  elif [ "$(echo "${jobState}" | jq -r '.result')" == "FAILURE" ]; then
    info "last status of job $JENKINS_JOB: $(echo "${jobState}" | jq -r '.')"
    error "Jenkins job $JENKINS_JOB failed"
  elif [ "$(echo "${jobState}" | jq -r '.building')" == "true" ]; then
    info "job $JENKINS_JOB is building"
    if [ "$(echo "${jobState}" | jq -r '._class')" == "org.jenkinsci.plugins.workflow.job.WorkflowRun" ]; then
      workflowJobState=$(curl --insecure --location -u "$jenkinsUserAuth" "$JENKINS_URL/job/$JENKINS_JOB/$JENKINS_BUILD_NUMBER/wfapi/describe" -sS) 2> workflow-job-state-curl-errors.txt
      info "job stage state:"
      echo "${workflowJobState}" | jq -r '.stages[] | .name,.status'
      if [ -s workflow-job-state-curl-errors.txt ]; then
        info "workflow job state curl errors:"
        cat workflow-job-state-curl-errors.txt
      fi
    fi
  else
    info "job $JENKINS_JOB is in an unknown state."
    info "build queue full state:"
    curl --insecure --location -u "$jenkinsUserAuth" "$JENKINS_URL/queue/api/json?pretty=true" -sS
    info "Jenkins load stats:"
    curl --insecure --location -u "$jenkinsUserAuth" "$JENKINS_URL/overallLoad/api/json?pretty=true" -sS
    info "job $JENKINS_JOB full state:"
    echo "${jobState}"
    info "job state curl errors:"
    cat job-state-curl-errors.txt
    info "job state curl headers:"
    cat job-state-headers.txt
  fi

  # If the timeout date has been reached and the job is not done, display error and exit
  if [[ "$(date +'%s')" -gt "$timeoutDate" && "$isJobDone" = "false" ]]; then
    info "last status of job $JENKINS_JOB: $(echo "${jobState}" | jq -r '.')"
    error "timed out waiting for Jenkins job $JENKINS_JOB to finish successfully"
  fi

  sleep $sleepCycle
done

info "Jenkins job $JENKINS_JOB finished successfully"
