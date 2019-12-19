require "ostruct"

module Heya
  class Config < OpenStruct
    def initialize(**opts)
      super({
        user_type: "User",
      }.merge(opts))
    end
  end
end
