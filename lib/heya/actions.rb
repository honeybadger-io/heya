module Heya
  module Actions
    Email = ->(contact:, message:) do
      CampaignMailer
        .with(contact: contact, message: message).build.deliver_now
    end
  end
end
