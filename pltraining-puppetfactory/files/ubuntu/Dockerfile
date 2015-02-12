# Builds a basic ubuntu container built on phusion/basimage with pe-agent installed.
# This image is for training purposes and is not intended for production environments.
FROM phusion/baseimage
MAINTAINER Josh Samuelson <js@puppetlabs.com>
ADD  https://s3.amazonaws.com/pe-builds/released/3.7.1/puppet-enterprise-3.7.1-ubuntu-14.04-amd64-agent.tar.gz /tmp/pe-agent.tar.gz
RUN tar xzvf /tmp/pe-agent.tar.gz
RUN for package in `ls /puppet-enterprise-3.7.1-ubuntu-14.04-amd64-agent/agent_packages/ubuntu-14.04-amd64/*.deb` ;\
    do \
      dpkg --force-depends -i $package ; \
    done
RUN rm -rf /puppet-enterprise-3.7.1-ubuntu-14.04-amd64-agent/
RUN apt-get update
RUN apt-get -y -f install
