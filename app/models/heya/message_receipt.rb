module Heya
  class MessageReceipt < ApplicationRecord
    self.table_name = "heya_message_receipts"

    belongs_to :message, class_name: "Message"
    belongs_to :contact, class_name: "Contact"
  end
end
