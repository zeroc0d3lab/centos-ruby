#!/bin/sh

RUBY=`which ruby`
RUBY_V=`ruby -v`
GEM=`which gem`
BUNDLE=`which bundle`

source $HOME/.bashrc

echo '-------------------------------------------------------------'
echo '## Ruby version: '
echo $RUBY_V
echo '-------------------------------------------------------------'
echo '## Path ruby in folder: '
echo $RUBY
echo '-------------------------------------------------------------'
echo '## Path gem in folder: '
echo $GEM

echo ''
echo 'Begin Installation'
echo '-------------------------------------------------------------'

$GEM install bundle
$BUNDLE install
