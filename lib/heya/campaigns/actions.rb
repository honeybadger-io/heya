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

      class Block < Action
        class Execution
          def initialize(user:, step:, &block)
            @user, @step, @block = user, step, block
          end

          def deliver
            instance_exec(@user, @step, &@block)
          end
        end

        def build
          block = step.properties.fetch(:block)
          Execution.new(user: user, step: step, &block)
        end
      end
    end
  end
end
