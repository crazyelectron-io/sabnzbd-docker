FROM ghcr.io/linuxserver/baseimage-alpine:3.15

# set version label
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
    gcc \
    libffi-dev \
    openssl-dev \
    python3-dev && \
  apk add  -U --update --no-cache \
    curl \
    p7zip \
    par2cmdline \
    python3 \
    py3-pip && \
  apk add -U --update --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.14/main \
    unrar && \
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
    /app/sabnzbd --strip-components=1 && \
  cd /app/sabnzbd && \
  python3 -m pip install --upgrade pip && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.15/ \
    wheel \
    apprise \
    pynzb \
    requests && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.15/ -r requirements.txt && \
  pip3 cache purge && \
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

# ports and volumes
EXPOSE 8080
VOLUME /config
