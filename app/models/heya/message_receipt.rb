module Heya
  class MessageReceipt < ApplicationRecord
    belongs_to :contact, polymorphic: true
  end
end
