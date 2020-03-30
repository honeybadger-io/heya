#!/usr/bin/env ruby
# frozen_string_literal: true

require "openssl"

if File.file?("license_key") || File.file?("license_key.pub")
  puts "Error: license key has already been generated"
  exit(1)
end

key_pair = OpenSSL::PKey::RSA.generate(2048)

File.open("license_key", "w") { |f| f.write(key_pair.to_pem) }

public_key = key_pair.public_key

File.open("license_key.pub", "w") { |f| f.write(public_key.to_pem) }
