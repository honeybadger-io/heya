require "ostruct"

module Heya
  class Config < OpenStruct
    def initialize(**opts)
      super({
        user_type: "User",
        priority: [],
      }.merge(opts))
    end
  end
end
