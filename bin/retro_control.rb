#!/usr/bin/env ruby
require 'bundler/setup'
require 'daemons'

Daemons.run File.expand_path('../retro.rb', __FILE__)

