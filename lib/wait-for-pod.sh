#!/usr/bin/env bash

set -e

error() {
  echo "ERROR: $1"
  exit 1
}

info() {
  echo "INFO: $1"
}

if [[ -z "$KUBERNETES_NAMESPACE" ]]; then
  error "\$KUBERNETES_NAMESPACE must be set to the namespace of the pod running."
fi

if [[ -z "$JOB_NAME" ]]; then
  error "\$JOB_NAME must be set to the name of the pod running."
fi

if [[ -z "$KEEP_JOB" ]]; then
    info "\$KEEP_JOB not set, will delete job once done"
fi

jobPod=$(kubectl -n ${KUBERNETES_NAMESPACE} get pods --selector=job-name=${JOB_NAME} --output=jsonpath={.items..metadata.name})
# wait for the job pod to be created
timeoutDate=$(date +'%s' --date="now + 5 minutes")
while [[ -z "${jobPod}" ]]; do
  jobPod=$(kubectl -n ${KUBERNETES_NAMESPACE} get pods --selector=job-name=${JOB_NAME} --output=jsonpath={.items..metadata.name})
  # make sure that we don't hit the rate limiter for the kube API
  sleep 5
  if [ "$(date +'%s')" -gt "$timeoutDate" ]; then
    error "timed out waiting for pod for job \"${JOB_NAME}\" to be created."
  fi
done

info "checking if pod is complete"
podPhase=$(kubectl -n ${KUBERNETES_NAMESPACE} get pod "$jobPod" -o jsonpath='{.status.phase}')
if [[ "$podPhase" != "Succeeded" && "$podPhase" != "Failed" ]]; then
  info "waiting up to 5 mins for pod to be ready"
  kubectl -n ${KUBERNETES_NAMESPACE} wait --timeout 300s --for=condition=Ready pod "$jobPod" \
    || true # don't fail if pod failed (still need logs and to delete job)
else
  info "pod already complete"
fi

kubectl -n ${KUBERNETES_NAMESPACE} logs "${jobPod}" --follow \
  || true
# in case the connection to the Kubernetes API for log collection dies early, wait until the pod stops running
while [ "$(kubectl -n ${KUBERNETES_NAMESPACE} get pod "${jobPod}" -o jsonpath='{.status.phase}')" == "Running" ]; do
  info "Reconnecting to log stream for job pod \"${jobPod}\". Some logs lines may have been lost."
  kubectl -n ${KUBERNETES_NAMESPACE} logs "${jobPod}" --follow --tail=0 \
    || true
  sleep 1
done

jobExitCode=""
timeoutDate=$(date +'%s' --date="now + 5 minutes")
while ! [[ "${jobExitCode}" =~ ^[0-9]+$ ]]; do
  jobExitCode=$(kubectl -n ${KUBERNETES_NAMESPACE} get pod "${jobPod}" -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}')
  if [ "$(date +'%s')" -gt "$timeoutDate" ]; then
    error "timed out waiting for an exit code for job pod \"${jobPod}\""
  fi
  info "Waiting for job pod \"${jobPod}\" to have an exit code."
  sleep 5
done

if [[ "$KEEP_JOB" != "true" ]]; then
  kubectl -n ${KUBERNETES_NAMESPACE} delete job "${JOB_NAME}"
fi

exit "${jobExitCode}"
