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

module Heya
  class License
    class Encryptor
      class Error < StandardError; end
      class KeyError < Error; end
      class DecryptionError < Error; end

      attr_accessor :key

      def initialize(key)
        if key && !key.is_a?(OpenSSL::PKey::RSA)
          raise KeyError, "No RSA encryption key provided."
        end

        @key = key
      end

      def encrypt(data)
        unless key.private?
          raise KeyError, "Provided key is not a private key."
        end

        # Encrypt the data using symmetric AES encryption.
        cipher = OpenSSL::Cipher::AES128.new(:CBC)
        cipher.encrypt
        aes_key = cipher.random_key
        aes_iv = cipher.random_iv

        encrypted_data = cipher.update(data) + cipher.final

        # Encrypt the AES key using asymmetric RSA encryption.
        encrypted_key = key.private_encrypt(aes_key)

        encryption_data = {
          "data" => Base64.encode64(encrypted_data),
          "key" => Base64.encode64(encrypted_key),
          "iv" => Base64.encode64(aes_iv)
        }

        json_data = JSON.dump(encryption_data)
        Base64.encode64(json_data)
      end

      def decrypt(data)
        unless key.public?
          raise KeyError, "Provided key is not a public key."
        end

        json_data = Base64.decode64(data.chomp)

        begin
          encryption_data = JSON.parse(json_data)
        rescue JSON::ParserError
          raise DecryptionError, "Encryption data is invalid JSON."
        end

        unless %w[data key iv].all? { |key| encryption_data[key] }
          raise DecryptionError, "Required field missing from encryption data."
        end

        encrypted_data = Base64.decode64(encryption_data["data"])
        encrypted_key = Base64.decode64(encryption_data["key"])
        aes_iv = Base64.decode64(encryption_data["iv"])

        begin
          # Decrypt the AES key using asymmetric RSA encryption.
          aes_key = self.key.public_decrypt(encrypted_key)
        rescue OpenSSL::PKey::RSAError
          raise DecryptionError, "AES encryption key could not be decrypted."
        end

        # Decrypt the data using symmetric AES encryption.
        cipher = OpenSSL::Cipher::AES128.new(:CBC)
        cipher.decrypt

        begin
          cipher.key = aes_key
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "AES encryption key is invalid."
        end

        begin
          cipher.iv = aes_iv
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "AES IV is invalid."
        end

        begin
          data = cipher.update(encrypted_data) + cipher.final
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "Data could not be decrypted."
        end

        data
      end
    end
  end
end
