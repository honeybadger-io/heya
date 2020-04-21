# frozen_string_literal: true

module Heya
  module Campaigns
    module Actions
      class Email < Action
        def self.validate_step(step)
          unless step.params["subject"].present? || I18n.exists?("#{step.campaign_name.underscore}.#{step.name.underscore}.subject")
            raise ArgumentError.new(%("subject" is required))
          end
        end

        def build
          CampaignMailer
            .with(user: user, step: step)
            .build
        end
      end
    end
  end
end
