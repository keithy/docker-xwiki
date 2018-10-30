# ---------------------------------------------------------------------------
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# ---------------------------------------------------------------------------
ARG BASE_IMAGE=tomcat
ARG BASE_TAG=8-jre8-slim

FROM ${BASE_IMAGE}:${BASE_TAG}

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

MAINTAINER Vincent Massol <vincent@massol.net>

# Note: when using docker-compose, the ARG values below may be overridden
# by invoking docker-compose build --build-arg
# Choose the version you want within the docker-compose.yml build: 
ARG DB=mysql
#ARG DB=postgres
ARG XWIKI_VERSION=10.8.1
ARG XWIKI_DOWNLOAD_SHA256=ed9436b5704e8cd4bc399c017f2ef7cf32e8f18f4e75a4fcc52782d933e9893c
ARG XWIKI_URL_PREFIX="http://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-distribution-war"
# Default environment values that a shell would have set but docker doesnt
ARG LOGNAME=xwiki
ARG USER=xwiki

# generic
COPY root/. /

# Use a proper readable bash file!
RUN /bin/bash -c "source /build/xwiki-tomcat.sh"

USER 888

# Make the XWiki directory (the permanent directory is included in it) persist on the host
# (so that it's not recreated across runs)
VOLUME /usr/local/xwiki

# At this point the image is done and what remains below are the runtime configuration used by the user to configure
# the container that will be created out of the image. Namely the user can override some environment variables with
#   docker run -e "var1=val1" -e "var2=val2" ...
# The supported environment variables that can be overridden are:
# - DB_USER: the name of the user configured for XWiki in the DB. Default is "xwiki". This is used to configure
#            xwiki's hibernate.cfg.xml file.
# - DB_PASSWORD: the password for the user configured for XWiki in the DB. Default is "xwiki". This is used to
#                configure xwiki's hibernate.cfg.xml file.
# - DB_DATABASE: the name of the database to use. Default is "xwiki". This is used to configure xwiki's
#                hibernate.cfg.xml file.
# - DB_HOST: The name of the host (or docker container) containing the database. Default is "db". This is used to
#            configure xwiki's hibernate.cfg.xml file.

# Default environment values
ENV LOGNAME=$LOGNAME
ENV USER=$USER
ENV XWIKI_VERSION=$XWIKI_VERSION
ENV DB_USER=xwiki
ENV DB_PASSWORD=xwiki
ENV DB_DATABASE=xwiki
ENV POSTGRES_ROOT_PASSWORD=xwiki
ENV MYSQL_ROOT_PASSWORD=xwiki

# Example:
#   docker run -it -e "DB_USER=xwiki" -e "DB_PASSWORD=xwiki" <imagename>

# Starts XWiki by starting Tomcat. All options passed to "docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG...]"
# are also passed to docker-entrypoint.sh. If "xwiki" is passed then XWiki will be configured the first time the
# container executes and Tomcat will be started. If some other parameter is passed then it'll be executed to comply
# with best practices defined at https://github.com/docker-library/official-images#consistency.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["xwiki"]
