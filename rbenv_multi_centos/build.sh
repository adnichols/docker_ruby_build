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
  curl wget rpm-build
RUN yum clean all
RUN rpm -ivh http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm

# Setup rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /usr/local/rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
RUN PREFIX=/usr/local/rbenv /usr/local/rbenv/plugins/ruby-build/install.sh
ENV PATH /usr/local/rbenv/bin:\$PATH
RUN echo 'eval "\$(rbenv init -)"' >> /etc/profile.d/rbenv.sh

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
ENV HOME /root
ADD ./versions.txt /root/versions.txt
RUN xargs -L 1 rbenv install < /root/versions.txt

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN bash -l -c 'for v in \$(cat /root/versions.txt); do rbenv global \$v; gem install bundler; done'

# Build package
ADD fpm /
RUN bash -l -c "bundle install"
RUN bash -l -c "bundle exec fpm --help"

RUN bash -l -c "bundle exec fpm \
  -s dir \
  -t rpm \
  -n rbenv-multi \
  -v $VERSION \
  -m '$MAINTAINER' \
  /usr/local/rbenv \
  /etc/profile.d/rbenv.sh"
EOF

docker build -rm -t rbenv_multi_centos .
docker run --rm -i -v `pwd`/pkg:/tmp/pkg -t rbenv_multi_centos cp /rbenv-multi-${VERSION}-1.x86_64.rpm /tmp/pkg/

# Cleanup
rm Dockerfile
