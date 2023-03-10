FROM ghcr.io/linuxserver/baseimage-alpine:3.16

# set version label
ARG UNRAR_VERSION=6.1.7
ARG BUILD_DATE
ARG VERSION
ARG SABNZBD_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
PYTHONIOENCODING=utf-8

RUN \
  echo "**** install packages ****" && \
  apk add -U --update --no-cache --virtual=build-dependencies \
    build-base \
    g++ \
    gcc \
    libffi-dev \
    make \
    openssl-dev \
    python3-dev
RUN apk add  -U --update --no-cache \
    curl \
    p7zip \
    par2cmdline \
    python3 \
    py3-pip
RUN echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \  
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1
RUN cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin
RUN echo "**** install sabnzbd ****" && \  
  if [ -z ${SABNZBD_VERSION+x} ]; then \
    SABNZBD_VERSION=$(curl -s https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir -p /app/sabnzbd && \
  curl -o \
    /tmp/sabnzbd.tar.gz -L \
    "https://github.com/sabnzbd/sabnzbd/releases/download/${SABNZBD_VERSION}/SABnzbd-${SABNZBD_VERSION}-src.tar.gz" && \
  tar xf \
    /tmp/sabnzbd.tar.gz -C \
    /app/sabnzbd --strip-components=1
RUN cd /app/sabnzbd && \
  python3 -m pip install --upgrade pip && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.16/ \
    wheel \
    apprise \
    pynzb \
    requests && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.16/ -r requirements.txt && \
  echo "**** cleanup ****" && \
  ln -s \
    /usr/bin/python3 \
    /usr/bin/python && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache

# add local files
COPY root/ /
COPY config.py /app/sabnzbd/sabnzbd/

# ports and volumes
EXPOSE 8080
VOLUME /config
