# -*- encoding: utf-8 -*-
require File.expand_path('../lib/astoria/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'astoria'
  s.version = Astoria::VERSION.dup
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.authors = ['Brian Moseley']
  s.description = 'A resource-oriented API service framework'
  s.email = ['bcm@cmaz.org']
  s.homepage = 'http://github.com/maz/astoria'
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options = ['--charset=UTF-8']
  s.summary = "A framework for building resource-oriented API services with Sinatra"
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files -- lib/*`.split("\n")
  s.test_files = `git ls-files -- {spec}/*`.split("\n")

  s.add_development_dependency('awesome_print')
  s.add_development_dependency('gemfury')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rack-test')
  s.add_runtime_dependency('activesupport')
  s.add_runtime_dependency('addressable')
  s.add_runtime_dependency('log_weasel', '>= 0.1.0')
  s.add_runtime_dependency('rack-oauth2')
  s.add_runtime_dependency('rack-routes')
  s.add_runtime_dependency('sequel')
  s.add_runtime_dependency('sinatra')
  s.add_runtime_dependency('yajl-ruby')
end
