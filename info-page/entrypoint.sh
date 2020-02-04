#!/usr/bin/env bash

# Cd into correct directory
cd /usr/share/nginx/html
# Detempletize index.html
mo --fail-not-set index.html.mo-template > index.html
#run nginx
exec nginx -g 'daemon off;'
