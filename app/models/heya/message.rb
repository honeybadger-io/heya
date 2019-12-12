module Heya
  class Message < ApplicationRecord
    self.table_name = "heya_messages"

    belongs_to :campaign, optional: true

    has_many :receipts, class_name: "MessageReceipt", dependent: :destroy

    delegate :action, :segment, :wait, :properties, to: :options
    delegate :contact_class, to: :campaign

    def build_segment
      contact_class
        .build_default_segment
        .instance_exec(&campaign.segment)
        .instance_exec(&segment)
    end

    private

    def options
      @options ||= campaign.klass.steps.fetch(name.to_sym)
    end
  end
end
