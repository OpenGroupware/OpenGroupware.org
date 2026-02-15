# syntax=docker/dockerfile:1
#
# OpenGroupware Local Build Image
#
# Like OGoDevImage, but builds from local sources (COPY)
# instead of fetching a tagged release from GitHub.
#
# Build from the OGo repo root:
#   docker build -t ogo-local-dev -f docker/OGoLocalBuild.dockerfile .
#
FROM ubuntu:noble

LABEL maintainer="Helge Heß <me@helgehess.eu>"

ENV DEBIAN_FRONTEND=noninteractive

# Install the things necessary for OGo, but also a set of debug
# tooling to work on issues.
# A real deployment image shouldn't do this once considered stable.
RUN apt-get -y -qq update \
 && apt-get -y -qq upgrade \
 && apt-get -y -qq install \
  libxml2-dev libldap2 libldap-dev libpq-dev libpq5 \
  libmemcached-dev libmemcached-tools libcurl4-openssl-dev \
  libcrypt-dev make libz-dev \
  gobjc \
  gnustep-make \
  gnustep-base-runtime \
  libgnustep-base-dev \
  zip \
  emacs less tree file \
  sudo gdb linux-tools-generic strace \
  netcat-openbsd lsof psmisc \
  git \
  links curl wget2 \
  vim \
  postgresql-client \
  apache2 \
  apache2-bin \
  apache2-data \
  apache2-utils


# Grab the SOPE sources from GitHub (tagged release, cached layer).
ENV SOPE_VERSION=6.0.6
ENV OGO_SOVERSION=5.5
ENV OGO_VERSION=${OGO_SOVERSION}.25
ENV OGO_ORGANIZATION=https://github.com/OpenGroupware
ENV SOPE_REPO=${OGO_ORGANIZATION}/SOPE

RUN mkdir /src
ADD ${SOPE_REPO}/archive/refs/tags/${SOPE_VERSION}.tar.gz \
    /src/SOPE.tar.gz
WORKDIR /src
RUN tar zxf SOPE.tar.gz && rm SOPE.tar.gz


# Compile and install SOPE
WORKDIR /src/SOPE-${SOPE_VERSION}
RUN ./configure \
  --with-gnustep \
  --enable-xml \
  --enable-postgresql \
  --enable-openldap \
  --with-ssl=ssl \
  --enable-debug \
  --disable-strip \
  && make -j 8 \
  && make install


# Enable the necessary Apache modules
RUN a2enmod proxy \
 && a2enmod proxy_http \
 && a2enmod proxy_balancer \
 && a2enmod lbmethod_byrequests \
 && a2enmod headers

# Add symlinks for OGo resources (targets provided by COPY below)
RUN mkdir /usr/local/share/opengroupware.org-${OGO_SOVERSION}/ \
 && ln -s /src/OGo/Themes/WebServerResources \
    /usr/local/share/opengroupware.org-${OGO_SOVERSION}/www \
 && ln -s /src/OGo/WebUI/Templates \
    /usr/local/share/opengroupware.org-${OGO_SOVERSION}/templates \
 && ln -s /src/OGo/WebUI/Resources \
    /usr/local/share/opengroupware.org-${OGO_SOVERSION}/translations

# Backward-compat symlink so startup scripts that reference
# /src/OpenGroupware.org-<version>/... keep working.
RUN ln -s /src/OGo \
    /src/OpenGroupware.org-${OGO_VERSION}


# Add OGo User
USER root
RUN useradd -u 700 --create-home --shell /bin/bash OGo

USER OGo
RUN mkdir -p /home/OGo/GNUstep/Defaults
COPY docker/OGo-globaldomain.plist \
     /home/OGo/GNUstep/Defaults/NSGlobalDomain.plist
COPY docker/OGo-webui.plist \
     /home/OGo/GNUstep/Defaults/ogo-webui-5.5.plist


# Add a user for development purposes.
# 501 is the macOS UID of the default user, gives us proper
# permissions
USER root
RUN useradd -u 501 --create-home --shell /bin/bash developer \
 && adduser developer sudo \
 && adduser developer root \
 && usermod -aG sudo developer

USER developer
RUN mkdir -p /home/developer/GNUstep/Defaults
COPY docker/Dev-globaldomain.plist \
     /home/developer/GNUstep/Defaults/NSGlobalDomain.plist
COPY docker/Dev-webui.plist \
     /home/developer/GNUstep/Defaults/ogo-webui-5.5.plist

USER root
COPY docker/startup-opengroupware       /usr/local/bin/
COPY docker/startup-opengroupware-stack /usr/local/bin/
RUN mkdir /var/run/opengroupware \
 && chown OGo /var/run/opengroupware \
 && mkdir /var/log/opengroupware \
 && chown OGo /var/log/opengroupware


# Copy local OGo sources into the image
COPY . /src/OGo

# Configure OGo (fast, regenerates config.make)
WORKDIR /src/OGo
RUN ./configure \
  --with-gnustep \
  --gsmake=/usr/share/GNUstep/Makefiles \
  --enable-debug \
  --disable-strip

# Build and install OGo.
# Uses a BuildKit cache mount to persist GNUstep-make obj/
# directories across rebuilds, enabling incremental
# compilation (only changed files are recompiled).
RUN --mount=type=cache,target=/tmp/ogo-buildcache \
    if [ -f /tmp/ogo-buildcache/obj.tar ]; then \
      tar xf /tmp/ogo-buildcache/obj.tar \
        2>/dev/null || true; \
    fi \
 && make -j 8 \
 && make install \
 && find . -name obj -type d \
      | tar cf /tmp/ogo-buildcache/obj.tar \
            -T - 2>/dev/null || true


# this should be set on the outside to a globally unique value
ENV OGO_INSTANCE_ID=OGo

ENV OGO_DATABASE_NAME=OGo
ENV OGO_DATABASE_USER=OGo
ENV OGO_DATABASE_PASSWORD=OGo
ENV OGO_DATABASE_HOST=postgres
ENV OGO_DATABASE_PORT=5432

# How many OGo Instances should be booted up.
ENV OGO_INSTANCE_COUNT=10
# Apache VServer Name, used for redirects!
ENV OGO_SERVER_NAME=localhost
ENV OGO_SERVER_PORT=443
ENV OGO_SERVER_PROTOCOL=https
ENV OGO_SERVER_ADMIN=webmaster@${OGO_SERVER_NAME}


# Default Startup
# Let's run Apache on 80, the default port
EXPOSE 80

USER    root
WORKDIR /tmp

# https://httpd.apache.org/docs/2.4/stopping.html#gracefulstop
STOPSIGNAL SIGWINCH

CMD [ "startup-opengroupware-stack" ]
