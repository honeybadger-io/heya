module Heya
  module Actions
    Email = ->(user:, step:) do
      CampaignMailer
        .with(user: user, step: step)
        .build
    end

    class Block
      class Execution; end

      def self.build(block)
        ->(user:, step:) {
          new(user, step, block)
        }
      end

      def initialize(user, step, block)
        @user = user
        @step = step
        @block = block
        @execution = Execution.new
      end

      def deliver_now
        @execution.instance_exec(@user, @step, &@block)
      end
      alias deliver_later deliver_now
    end
  end
end
