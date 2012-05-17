require 'active_support/core_ext/hash/keys'
require 'rspec/core'
require 'rspec/matchers'

RSpec::Matchers.define :be_count_query_result do |count|
  match do |response|
    response.status.should == 200 && response.json[:count].should == count
  end
  failure_message_for_should do |response|
    "Response #{response.json[:count]} should be json count query result #{count}"
  end
end

RSpec::Matchers.define :be_grouped_query_result do |grouped|
  match do |response|
    response.status.should == 200 && response.json.should == expected(grouped)
  end
  failure_message_for_should do |response|
    "Response #{response.json} should be json grouped query result #{expected(grouped)}"
  end
  def expected(grouped)
    grouped.stringify_keys
  end
end

RSpec::Matchers.define :be_paged_query_result do |total, collection|
  match do |response|
    response.status.should == 200 && response.json[:total].should == total && (
      response.json[:collection].each_with_index {|o, i| o[:id].should == collection[i].id}
    )
  end
  failure_message_for_should do |response|
    "Response #{response.json} should be json paged query result #{expected(total, collection)}"
  end
  def expected(total, collection)
    {'total' => total, 'collection' => collection.map(&:values)}
  end
end
