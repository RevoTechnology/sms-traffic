require 'bundler/setup'
Bundler.setup
require 'active_support/core_ext/hash/conversions'

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require 'smstraffic'

RSpec.configure do |config|
end
