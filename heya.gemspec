$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "heya/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = "heya"
  spec.version = Heya::VERSION
  spec.authors = ["Joshua Wood"]
  spec.email = ["josh@honeybadger.io"]
  spec.homepage = "https://www.honeybadger.io"
  spec.summary = "Heya 👋"
  spec.description = "Heya 👋"
  # spec.license     = "TODO"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]

  spec.add_dependency "rails", "~> 5.2.3"

  spec.add_development_dependency "pg"
end
