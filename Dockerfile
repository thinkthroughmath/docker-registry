# VERSION 0.1
# DOCKER-VERSION  0.7.3
# AUTHOR:         Sam Alba <sam@docker.com>
# DESCRIPTION:    Image with docker-registry project and dependecies
# TO_BUILD:       docker build -rm -t registry .
# TO_RUN:         docker run -p 5000:5000 registry

# Latest Ubuntu LTS
FROM ubuntu:14.04

# Update
RUN apt-get update \
# Install pip
    && apt-get install -y \
        python-pip \
# Install deps for backports.lmza (python2 requires it)
        python-dev \
        liblzma-dev \
        libevent1-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /docker-registry
COPY ./config/boto.cfg /etc/boto.cfg

# Install core
RUN pip install /docker-registry/depends/docker-registry-core

# Install registry
RUN pip install file:///docker-registry#egg=docker-registry[bugsnag,newrelic,cors]

RUN patch \
 $(python -c 'import boto; import os; print os.path.dirname(boto.__file__)')/connection.py \
 < /docker-registry/contrib/boto_header_patch.diff

# TTM Modifications
RUN apt-get -y install wget 
RUN /bin/cat > /etc/apt/sources.list.d/nginx.list <<< "deb http://nginx.org/packages/ubuntu/ trusty nginx"
RUN /usr/bin/wget --quiet -O - http://nginx.org/keys/nginx_signing.key | /usr/bin/apt-key add -

RUN apt-get -y update
RUN apt-get -y install nginx supervisor apache2-utils

COPY ./contrib/ttm/nginx.conf /etc/nginx/nginx.conf
COPY ./contrib/ttm/supervisord-registry.conf /etc/supervisor/conf.d/registry.conf

ENV DOCKER_REGISTRY_CONFIG /docker-registry/config/config_sample.yml
ENV SETTINGS_FLAVOR dev

EXPOSE 443

CMD ["supervisord"]
