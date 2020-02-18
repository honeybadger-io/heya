require "test_helper"

module Heya
  module Campaigns
    module Actions
      class EmailTest < ActiveSupport::TestCase
        include ActionMailer::TestHelper

        test "it sends an email to user" do
          contact = contacts(:one)
          step = FirstCampaign.steps.first

          assert_emails 1 do
            Email.new(user: contact, step: step).deliver_now
          end
        end

        test "it queues a default job for step" do
          contact = contacts(:one)
          step = FirstCampaign.steps.first

          assert_enqueued_with(job: StepActionJob, queue: "heya") do
            Email.new(user: contact, step: step).deliver_later
          end
        end
      end
    end
  end
end
