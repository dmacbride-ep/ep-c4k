#!/bin/bash
set -e

info() {
    echo "INFO: $1"
}

test_string="$1"

project_list=""

if [[ ${test_string} == "" ]]; then
    info "No list was provided. All EP-Commerce tests will be run."
else
    project_list="-pl ${test_string}"
fi

info "Running Commerce with maven command string: 'mvn -f EP-Commerce/pom.xml -B -U -e ${project_list} -P pass-build-even-if-tests-fail clean install'"

mvn -f ep-commerce/pom.xml -B -U -e \
    ${project_list} \
    -P pass-build-even-if-tests-fail \
    clean install
