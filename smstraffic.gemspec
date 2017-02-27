# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smstraffic/version'

Gem::Specification.new do |spec|
  spec.name          = "smstraffic"
  spec.version       = Smstraffic::VERSION
  spec.authors       = ["Neodelf"]
  spec.email         = ["neodelf@gmail.com"]

  spec.summary       = %q{Send sms via SMSTraffic service.}
  spec.description   = %q{Send sms via SMSTraffic service.}
  spec.homepage      = "https://github.com/RevoTechnology/sms-traffic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_dependency 'activesupport'
  spec.add_dependency 'russian'
end
