module Heya
  module Campaigns
    class StepActionJob < ActiveJob::Base
      queue_as { Heya.config.campaigns.queue }

      rescue_from StandardError, with: :handle_exception_with_campaign_class

      def perform(_campaign, user, step)
        step.action.new(user: user, step: step).deliver_now
      end

      private

      # From ActionMailer: "deserialize" the mailer class name by hand in case
      # another argument (like a Global ID reference) raised
      # DeserializationError.
      def campaign_class
        if (campaign = (arguments_serialized? && Array(@serialized_arguments).first) || Array(arguments).first)
          campaign.constantize
        end
      end

      def handle_exception_with_campaign_class(exception)
        if (klass = campaign_class)
          klass.handle_exception(exception)
        else
          raise exception
        end
      end
    end
  end
end
