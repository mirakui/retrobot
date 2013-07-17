#!/usr/bin/env ruby
require 'bundler/setup'
require 'daemons'
require 'pathname'

base_dir = Pathname('../../').expand_path(__FILE__)
Daemons.run(
  base_dir.join('bin/retro.rb'),
  app_name: 'retrobot',
  dir_mode: :normal,
  dir: base_dir.join('tmp'),
  log_dir: base_dir.join('log'),
  log_output: true
)
