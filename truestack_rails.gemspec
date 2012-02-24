# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "truestack_rails/version"

Gem::Specification.new do |s|
  s.name        = "truestack_rails"
  s.version     = TruestackRails::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Greenfry Labs"]
  s.email       = ["gems@greenfrylabs.com"]
  s.homepage    = "http://www.truestack.com"
  s.summary     = %q{Attaches to rails app, and logs / processes all the information}
  s.description = %q{Attaches to rails, sends pertinent data to truestack - and you have insight into your app}

  s.rubyforge_project = "truestack_rails"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency 'truestack_client', :git => "git@github.com:caryfitzhugh/truestack_client.git"
end
