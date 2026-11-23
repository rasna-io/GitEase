# Build environment for the Linux .deb.
#
# The base image sets the oldest glibc the package runs on: binaries built here
# only use glibc symbols that exist in this image, so they also run on every
# newer distro. ubuntu:20.04 = glibc 2.31 (Ubuntu 20.04+, Debian 11+).
#
# Qt comes from Qt's own binaries (downloaded with aqtinstall, no Qt account
# needed). It has to run on this glibc: Qt 6.5 - 6.9 need 2.28; Qt 6.10+ needs
# 2.34 and cannot be used here.
ARG BASE_IMAGE=ubuntu:20.04

# ---------- Qt ----------
# aqtinstall needs a newer Python than ubuntu:20.04 has, so fetch Qt in its own stage.
# qtshadertools: Qt5Compat.GraphicalEffects links libQt6ShaderTools (the Qt
# installer adds it as a dependency, aqtinstall does not).
FROM python:3.12-slim AS qt
ARG QT_VERSION=6.8.3
RUN pip install --no-cache-dir aqtinstall \
    && aqt install-qt linux desktop "${QT_VERSION}" linux_gcc_64 \
           -m qt5compat qtshadertools --outputdir /opt/Qt \
    && rm -rf /opt/Qt/*.log /root/.cache \
    && test -x "/opt/Qt/${QT_VERSION}/gcc_64/bin/qmake"

# ---------- Build image ----------
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG CMAKE_VERSION=3.30.5
ARG QT_VERSION=6.8.3

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential binutils file dpkg-dev patchelf \
        ca-certificates curl wget git xz-utils perl python3 ninja-build pkg-config \
        zlib1g-dev libbz2-dev liblzma-dev libkrb5-dev \
        libgl1-mesa-dev libegl1-mesa-dev libopengl0 libglib2.0-dev libdbus-1-dev \
        libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev \
        libxkbcommon-dev libxkbcommon-x11-dev \
        libxcb1-dev libxcb-cursor0 libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev \
        libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev \
        libxcb-shape0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev \
        libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev \
    && rm -rf /var/lib/apt/lists/*

# The distro CMake is too old for Qt 6 (20.04 ships 3.16); use Kitware's build.
RUN curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" \
        | tar xz -C /opt \
    && ln -s /opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/* /usr/local/bin/

COPY --from=qt /opt/Qt /opt/Qt
ENV QT_VERSION=${QT_VERSION}

# The container runs as the host user (files in the mounted tree stay theirs);
# give that user a writable HOME.
ENV HOME=/tmp/home
RUN mkdir -p /tmp/home && chmod 1777 /tmp/home

WORKDIR /src
