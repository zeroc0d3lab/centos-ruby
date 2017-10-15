#!/bin/sh

RUBY=`which ruby`
RUBY_V=`ruby -v`
GEM=`which gem`
BUNDLE=`which bundle`

if [ "${RUBY_PACKAGE}" = "rbenv" ]
then
  #-----------------------------------------------------------------------------
  # Install Ruby with rbenv (default)
  #-----------------------------------------------------------------------------
  git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv \
    && git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build \
    && $HOME/.rbenv/bin/rbenv install ${RUBY_VERSION} \
    && $HOME/.rbenv/bin/rbenv global ${RUBY_VERSION} \
    && $HOME/.rbenv/bin/rbenv rehash \
    && $HOME/.rbenv/shims/ruby -v
else
  #-----------------------------------------------------------------------------
  # Install Ruby with rvm (alternatives)
  #-----------------------------------------------------------------------------
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
    && curl -sSL https://get.rvm.io | sudo bash -s stable \
    && sudo usermod -a -G rvm root \
    && sudo usermod -a -G rvm docker \
    && source $HOME/.bashrc \
    && /usr/local/rvm/bin/rvm install ${RUBY_VERSION} \
    && /usr/local/rvm/bin/rvm use ${RUBY_VERSION} --default \
    && /usr/bin/ruby -v
fi

source $HOME/.bashrc

$GEM install bundle