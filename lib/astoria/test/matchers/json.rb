require 'active_support/core_ext/hash/indifferent_access.rb'
require 'rack/test'
require 'rspec/core'
require 'rspec/matchers'
require 'yajl'

RSpec::Matchers.define :be_json do
  match do |response|
    response.content_type =~ /^application\/json/
  end
  failure_message_for_should do |response|
    "Response should have application/json content type"
  end
  failure_message_for_should_not do |response|
    "Response should not have application/json content type"
  end
end

module Rack
  class MockResponse
    def json
      unless @json
        obj = Yajl::Parser.parse(body)
        obj = HashWithIndifferentAccess.new(obj) if obj.is_a?(Hash)
        @json = obj
      end
      @json
    end
  end
end
