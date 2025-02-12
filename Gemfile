source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in heya.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

group :development, :test do
  gem "standard", "~> 1.45.0"
  gem "yard", "~> 0.9.36"
end

gem "minitest-ci", group: :test

gem "simplecov", require: false, group: :test

gem "timecop", "~> 0.9.2"

gem "pry", "~> 0.15.0"

gem "pry-rails", "~> 0.3.9"
