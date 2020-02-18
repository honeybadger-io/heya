module Heya
  module Campaigns
    class Action
      def initialize(user:, step:)
        @user, @step = user, step
      end

      attr_reader :user, :step

      def build
        raise NotImplementedError, "Please implement #build on subclass of Heya::Campaigns::Action."
      end

      def deliver_now
        build.deliver
      end

      def deliver_later
        StepActionJob
          .set(queue: step.queue)
          .perform_later(step.campaign.class.name, user, step)
      end
    end
  end
end
