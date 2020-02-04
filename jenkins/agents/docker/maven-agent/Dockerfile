FROM ubuntu:bionic

LABEL maintainer="EP/DevOps <rel-eng@elasticpath.com>"

ARG encodedOracleJdkDownloadUrl
ARG jdkFolderName

ARG mavenDownloadUrl
ARG mavenFolderName

RUN apt-get update && apt-get -y upgrade && apt-get -y install wget xmlstarlet curl uuid

RUN curl --retry-connrefused --retry-delay 5 https://raw.githubusercontent.com/kadwanev/retry/master/retry -o /usr/local/bin/retry && chmod 755 /usr/local/bin/retry

RUN export oracleJdkDownloadUrl=$(echo "$encodedOracleJdkDownloadUrl" | base64 -d) && \
    wget --progress=dot:mega -O /tmp/maven.tar.gz $mavenDownloadUrl && \
    wget --progress=dot:mega -O /tmp/jdk.tar.gz $oracleJdkDownloadUrl && \
    tar -C /opt -zxf /tmp/jdk.tar.gz && \
    tar -C /opt -zxf /tmp/maven.tar.gz && \
    rm -rf /tmp/*.tar.gz

ENV JAVA_HOME=/opt/$jdkFolderName
ENV MAVEN_HOME=/opt/$mavenFolderName
ENV MAVEN_OPTS='-Xmx1536m'
ENV PATH="${PATH}:${JAVA_HOME}/bin:${MAVEN_HOME}/bin"

WORKDIR /root

RUN java -version && mvn -version
