# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack_my_openid/version"

Gem::Specification.new do |s|
  s.name        = "rack_my_openid"
  s.version     = RackMyOpenid::VERSION
  s.authors     = ["Leonid Shevtsov"]
  s.email       = ["leonid@shevtsov.me"]
  s.homepage    = "https://github.com/leonid-shevtsov/rack_my_openid"
  s.summary     = %q{Single-user OpenID provider implemented as a Rack (Sinatra) application.}
  s.description = %q{Would be useful to enable OpenID authorisation with your Ruby/Rails-based blog, personal website or whatever.}

  s.rubyforge_project = "rack_my_openid"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rack', '>=1.2'
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'ruby-openid'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
end
