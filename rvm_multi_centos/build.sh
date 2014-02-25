#!/bin/bash
VERSION="$(cat ./build_version.txt)"
ITERATION=1
MAINTAINER="Aaron Nichols <anichols@trumped.org>"

cat > Dockerfile <<EOF
FROM centos:latest
MAINTAINER Aaron Nichols anichols@trumped.org

RUN yum -y install gcc-c++ patch readline readline-devel \
  zlib zlib-devel libyaml-devel libffi-devel openssl-devel \
  make bzip2 autoconf automake libtool bison iconv-devel git-core \
  curl wget rpm-build which
RUN yum clean all
RUN ln -sf /proc/self/fd /dev/fd
RUN rpm -ivh http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm

# Setup RVM
RUN curl -L https://get.rvm.io | bash -s stable --ruby
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc
RUN /bin/bash -l -c rvm requirements

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ADD ./versions.txt /root/versions.txt

RUN /bin/bash -l -c 'for v in \$(cat /root/versions.txt); do rvm install \$v; done'
RUN /bin/bash -l -c 'for v in \$(cat /root/versions.txt); do rvm use \$v; gem install bundler; done'

# Build package
ADD fpm /
RUN bash -l -c "bundle install"
RUN bash -l -c "bundle exec fpm --help"

RUN bash -l -c "bundle exec fpm \
  -s dir \
  -t rpm \
  -n rvm-multi \
  -v $VERSION \
  -m '$MAINTAINER' \
  /usr/local/rvm"
EOF

docker build -rm -t rvm_multi_centos .
docker run --rm -i -v `pwd`/pkg:/tmp/pkg -t rvm_multi_centos cp /rvm-multi-${VERSION}-1.x86_64.rpm /tmp/pkg
