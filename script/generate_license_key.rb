#!/usr/bin/env ruby
# frozen_string_literal: true

require "openssl"

if File.file?("license_key") || File.file?("license_key.pub")
  puts "Error: license key has already been generated"
  exit(1)
end

key_pair = OpenSSL::PKey::RSA.generate(2048)

File.write("license_key", key_pair.to_pem)

public_key = key_pair.public_key

File.write("license_key.pub", public_key.to_pem)
