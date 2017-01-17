# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ssml2mp3/version'

Gem::Specification.new do |spec|
  spec.name          = "ssml2mp3"
  spec.version       = Ssml2mp3::VERSION
  spec.authors       = ["hogelog"]
  spec.email         = ["konbu.komuro@gmail.com"]

  spec.summary       = %q{SSML to mp3 synthesizer powered by Amazon Polly}
  spec.homepage      = "https://github.com/hogelog/ssml2mp3"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-polly", "1.0.0.rc2"
  spec.add_dependency "nokogiri", ">= 1.6"
  spec.add_dependency "htmlentities"
  spec.add_dependency "expeditor", "~> 0.5.0"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
