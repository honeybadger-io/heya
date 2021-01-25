$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "heya/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = "heya"
  spec.version = Heya::VERSION
  spec.authors = ["Joshua Wood"]
  spec.email = ["josh@honeybadger.io"]
  spec.homepage = "https://github.com/honeybadger-io/heya"
  spec.summary = "Heya 👋"
  spec.description = "Heya is a campaign mailer for Rails. Think of it like ActionMailer, but for timed email sequences. It can also perform other actions like sending a text message."
  spec.license = "Prosperity Public License"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md", "license_key.pub"]

  spec.add_dependency "rails", ">= 5.2.3", "< 6.2.0"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "appraisal"
end
