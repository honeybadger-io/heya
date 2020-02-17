require "ostruct"

module Heya
  class Config < OpenStruct
    def initialize(**opts)
      super({
        user_type: "User",
        priority: [],
        from: nil,
        queue: "heya",
      }.merge(opts))
    end
  end
end
