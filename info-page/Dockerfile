FROM nginx:alpine
EXPOSE 80
COPY . /usr/share/nginx/html


# Install required programs
RUN apk update \
    && apk upgrade \
    && apk add --update curl bash \
    && rm -rf /var/cache/apk/*

# Add Mo
RUN curl --connect-timeout 5 --speed-limit 10000 --speed-time 5 --location \
  --retry 10 --retry-max-time 300 --show-error --silent \
  https://raw.githubusercontent.com/tests-always-included/mo/master/mo --output mo && \
  chmod +x mo && \
  mv mo /usr/local/bin/

RUN chmod 700 /usr/share/nginx/html/entrypoint.sh
ENTRYPOINT ["/usr/share/nginx/html/entrypoint.sh"]
