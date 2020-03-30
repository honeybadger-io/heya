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
    module Boundary
      BOUNDARY_START = /(\A|\r?\n)-*BEGIN .+? LICENSE-*\r?\n/.freeze
      BOUNDARY_END = /\r?\n-*END .+? LICENSE-*(\r?\n|\z)/.freeze

      class << self
        def add_boundary(data, product_name)
          data = remove_boundary(data)

          product_name.upcase!

          pad = lambda do |message, width|
            total_padding = [width - message.length, 0].max

            padding = total_padding / 2.0
            [
              "-" * padding.ceil,
              message,
              "-" * padding.floor
            ].join
          end

          [
            pad.call("BEGIN #{product_name} LICENSE", 60),
            data.strip,
            pad.call("END #{product_name} LICENSE", 60)
          ].join("\n")
        end

        def remove_boundary(data)
          after_boundary = data.split(BOUNDARY_START).last
          in_boundary = after_boundary.split(BOUNDARY_END).first

          in_boundary
        end
      end
    end
  end
end
