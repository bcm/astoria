require 'rspec/core'
require 'rspec/matchers'

RSpec::Matchers.define :be_entity_get_result do |entity|
  match do |response|
    response.status.should == 200 && response.json[:id].should == entity.id
  end
  failure_message_for_should do |response|
    "Response #{response.body} should be json entity get result #{entity.to_json}"
  end
end

RSpec::Matchers.define :be_entity_put_result do |attributes|
  match do |response|
    response.status.should == 201 && (
      attributes.each_pair {|attribute, value| response.json[attribute].should == value}
    )
  end
  failure_message_for_should do |response|
    "Response #{response.body} should be json entity put result #{entity.to_json}"
  end
end

RSpec::Matchers.define :be_entity_delete_result do
  match do |response|
    response.status.should == 204 && response.body.should == ''
  end
  failure_message_for_should do |response|
    "Response #{response.body} should be json entity delete result"
  end
end
