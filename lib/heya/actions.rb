module Heya
  module Actions
    Email = ->(contact:, message:) do
      CampaignMailer
        .with(contact: contact, message: message)
        .build
        .deliver_later
    end
  end
end
