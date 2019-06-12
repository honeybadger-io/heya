module Heya
  class Message < ApplicationRecord
    self.table_name = "heya_messages"

    belongs_to :campaign, optional: true

    has_many :receipts, class_name: "MessageReceipt"

    attr_accessor :properties
  end
end
