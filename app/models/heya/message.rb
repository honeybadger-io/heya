module Heya
  class Message < ApplicationRecord
    self.table_name = "heya_messages"

    belongs_to :campaign, optional: true

    has_many :receipts, class_name: "MessageReceipt", dependent: :destroy

    delegate :contact_class, :action, :segment, :wait, :properties, to: :options

    def contact_class
      @contact_class ||= options.contact_class.constantize
    end

    def segment
      @segment ||= contact_class.instance_exec(&options.segment)
    end

    private

    def options
      @options ||= campaign.klass.steps.fetch(name.to_sym)
    end
  end
end
