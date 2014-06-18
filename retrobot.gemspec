# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'retrobot/version'

Gem::Specification.new do |gem|
  gem.name          = "retrobot"
  gem.version       = Retrobot::VERSION
  gem.authors     = ["Issei Naruta"]
  gem.email       = ["mimitako@gmail.com"]
  gem.description   = %q{Bot for twitter, which tweets a word that you've tweeted just 1 year ago}
  gem.summary       = %q{Retrobot tweets a word that you've tweeted just 1 year ago. (example: @mirakui_retro)}
  gem.homepage      = "https://github.com/mirakui/retrobot"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'twitter', '~> 5.8'
  gem.add_dependency 'activesupport', '~> 4.0'
  gem.add_dependency 'retryable'
  gem.add_dependency 'daemons'

  gem.add_development_dependency 'rspec', '= 2.99'
  gem.add_development_dependency 'timecop'

  gem.add_runtime_dependency 'get-twitter-oauth-token'
end
