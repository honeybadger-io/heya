module Heya
  module Campaigns
    module Actions
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
          block = step.params.fetch(:block)
          Execution.new(user: user, step: step, &block)
        end
      end
    end
  end
end
