module Heya
  class MessageReceipt < ApplicationRecord
    belongs_to :message, class_name: "Message"
    belongs_to :contact, polymorphic: true
  end
end
