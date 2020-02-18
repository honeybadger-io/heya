require "ostruct"

module Heya
  class Config < OpenStruct
    def initialize
      super(
        user_type: "User",
        campaigns: OpenStruct.new(
          priority: [],
          default_options: {},
        ),
      )
    end
  end
end
