# frozen_string_literal: true

module Heya
  module Campaigns
    module Actions
      class Email < Action
        def build
          CampaignMailer
            .with(user: user, step: step)
            .build
        end
      end
    end
  end
end
