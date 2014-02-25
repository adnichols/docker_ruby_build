#!/bin/bash
VERSION="$(cat ./build_version.txt)"
MAINTAINER="Aaron Nichols <anichols@trumped.org>"

cat > Dockerfile <<EOF
FROM ubuntu:12.04
MAINTAINER Aaron Nichols anichols@trumped.org

RUN apt-get update
RUN apt-get -y install libssl-dev libxslt-dev libxml2-dev git vim libevent-dev ncurses-dev build-essential
RUN apt-get -y install curl wget zlib1g-dev libreadline-dev libyaml-dev 
RUN apt-get clean

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
  -t deb \
  -n rbenv-multi \
  -v $VERSION \
  -m '$MAINTAINER' \
  /usr/local/rbenv \
  /etc/profile.d/rbenv.sh"
EOF

docker build -rm -t rbenv_multi_ubuntu .
docker run --rm -i -v `pwd`/pkg:/tmp/pkg -t rbenv_multi_ubuntu cp /rbenv-multi_${VERSION}_amd64.deb /tmp/pkg/
