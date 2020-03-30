#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

require "openssl"
require "json"
require "pathname"
require "active_support/core_ext"
require "heya/license"

LICENSE_KEY = Pathname(ENV["LICENSE_KEY"] || File.expand_path("../license_key", __dir__))

def assert(condition, error_message)
  return if condition
  puts error_message
  exit(1)
end

assert(LICENSE_KEY.exist?, "Error: license key must be generated first. See script/generate_license_key.rb")

private_key = OpenSSL::PKey::RSA.new(LICENSE_KEY.read)
Heya::License.encryption_key = private_key

license = Heya::License.new

puts "Name:"
name = gets.strip
assert(name.present?, "Error: Name required")

puts "Company:"
company = gets.strip
assert(company.present?, "Error: Company required")

puts "Email:"
email = gets.strip
assert(email.present?, "Error: Email required")

puts "User count (default: unlimited):"
user_count = if (count = gets.strip).present?
  count.to_i
end

license.licensee = {
  "Name" => name,
  "Company" => company,
  "Email" => email
}

license.starts_at = Date.today
license.expires_at = 1.year.from_now.to_date

license.restrictions = {
  user_count: user_count
}

puts "License:"
puts JSON.pretty_generate(license.attributes)

data = license.export

puts "Exported license:"
puts data

File.open("Heya.heya-license", "w") { |f| f.write(data) }
