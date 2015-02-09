# Builds a basic Centos6 container with pe-agent installed.
# This image is for training purposes and is not intended for production environments.
FROM centos:6
MAINTAINER Josh Samuelson <js@puppetlabs.com>
ENV HOME /root/
ENV TERM xterm
RUN yum -y install sudo tar dmidecode which logrotate cyrus-sasl libxslt cronie
ADD https://s3.amazonaws.com/pe-builds/released/3.7.1/puppet-enterprise-3.7.1-el-6-x86_64-agent.tar.gz /tmp/pe-agent.tar.gz
RUN tar xzvf /tmp/pe-agent.tar.gz
RUN rpm -ivh --nodeps `ls /puppet-enterprise-3.7.1-el-6-x86_64-agent/agent_packages/el-6-x86_64/*rpm`
RUN rm -rf /puppet-enterprise-3.7.1-el-6-x86_64-agent/
RUN rm -f /tmp/pe-agent.tar.gz
