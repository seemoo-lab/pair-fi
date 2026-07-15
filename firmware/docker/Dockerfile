FROM ubuntu:24.04 AS builder

SHELL ["/bin/bash", "-c"]

# install dependencies
RUN touch /etc/apt/sources.list.d/ubuntu-focal-sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" | tee -a /etc/apt/sources.list.d/ubuntu-focal-sources.list \
  && dpkg --add-architecture i386 \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends \
    bison \
    build-essential \
    flex \
    gawk \
    git \
    ca-certificates \
    libc6:i386 \
    libfl-dev \
    libncurses5:i386 \
    libstdc++6:i386 \
    make \
    qpdf \
    xxd \
    zip \
  && rm -rf /var/lib/apt/lists/*

# create temporary output directory
RUN mkdir -p /artifacts

# setup nexmon framework
WORKDIR /build/nexmon
RUN git init \
  && git remote add origin https://github.com/seemoo-lab/nexmon.git \
  && git fetch --depth 1 origin d6b633800d80b8b8e2132a2c9a5ecda870ec8aaa \
  && git reset --hard FETCH_HEAD \
  && touch DISABLE_STATISTICS \
  && sed -i 's/\$(dir.*$/bcm4389c1\//' firmwares/Makefile \
  && mkdir -p patches/bcm4389c1/20_101_57_r1035009/pairfi/ \
  && . ./setup_env.sh \
  && make

# build patched firmware for bcm4389c1 of Google Pixel 7 and embed in Magisk module
COPY pairfi-nexmon-patch/ /build/nexmon/patches/bcm4389c1/20_101_57_r1035009/pairfi/
RUN . ./setup_env.sh \
  && make -C /build/nexmon/patches/bcm4389c1/20_101_57_r1035009/pairfi \
  && cp /build/nexmon/patches/bcm4389c1/20_101_57_r1035009/pairfi/pairfi-nexmon-magisk.zip /artifacts/

# ------------------------------------------------------------
# Export artifacts
# ------------------------------------------------------------
FROM scratch AS export
COPY --from=builder /artifacts/ /
