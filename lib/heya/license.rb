# frozen_string_literal: true

# The MIT License (MIT)
#
# Copyright (c) 2015 GitLab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "openssl"
require "date"
require "json"
require "base64"

require "heya/license/encryptor"
require "heya/license/boundary"

module Heya
  class License
    class Error < StandardError; end
    class ImportError < Error; end
    class ValidationError < Error; end

    class << self
      attr_reader :encryption_key
      @encryption_key = nil

      def encryption_key=(key)
        key = OpenSSL::PKey::RSA.new(key.to_s) unless key&.is_a?(OpenSSL::PKey::RSA)
        @encryption_key = key
        @encryptor = nil
      end

      def encryptor
        @encryptor ||= Encryptor.new(encryption_key)
      end

      def import(data)
        if data.nil?
          raise ImportError, "No license data."
        end

        data = Boundary.remove_boundary(data)

        begin
          license_json = encryptor.decrypt(data)
        rescue Encryptor::Error
          raise ImportError, "License data could not be decrypted."
        end

        begin
          attributes = JSON.parse(license_json)
        rescue JSON::ParseError
          raise ImportError, "License data is invalid JSON."
        end

        new(attributes)
      end
    end

    attr_reader :version
    attr_accessor :licensee, :starts_at, :expires_at
    attr_accessor :restrictions

    def initialize(attributes = {})
      load_attributes(attributes)
    end

    def valid?
      return false if !licensee || !licensee.is_a?(Hash) || licensee.length == 0
      return false if !starts_at || !starts_at.is_a?(Date)
      return false if expires_at && !expires_at.is_a?(Date)
      return false if restrictions && !restrictions.is_a?(Hash)

      true
    end

    def validate!
      raise ValidationError, "License is invalid" unless valid?
    end

    def will_expire?
      expires_at
    end

    def expired?
      will_expire? && Date.today >= expires_at
    end

    def restricted?(key = nil)
      if key
        restricted? && restrictions.has_key?(key)
      else
        restrictions && restrictions.length >= 1
      end
    end

    def attributes
      hash = {}

      hash["version"] = version
      hash["licensee"] = licensee

      hash["starts_at"] = starts_at
      hash["expires_at"] = expires_at if will_expire?

      hash["restrictions"] = restrictions if restricted?

      hash
    end

    def to_json
      JSON.dump(attributes)
    end

    def export(boundary: nil)
      validate!

      data = self.class.encryptor.encrypt(to_json)

      if boundary
        data = Boundary.add_boundary(data, boundary)
      end

      data
    end

    private

    def load_attributes(attributes)
      attributes = Hash[attributes.map { |k, v| [k.to_s, v] }]

      version = attributes["version"] || 1
      unless version && version == 1
        raise ArgumentError, "Version is too new"
      end

      @version = version

      @licensee = attributes["licensee"]

      %w[starts_at expires_at].each do |attr|
        value = attributes[attr]
        if value.is_a?(String)
          value = begin
                    Date.parse(value)
                  rescue
                    nil
                  end
        end

        next unless value

        send("#{attr}=", value)
      end

      restrictions = attributes["restrictions"]
      if restrictions&.is_a?(Hash)
        restrictions = Hash[restrictions.map { |k, v| [k.to_sym, v] }]
        @restrictions = restrictions
      end
    end
  end
end
