module Heya
  module Actions
    Email = ->(contact:, step:) do
      CampaignMailer
        .with(contact: contact, step: step)
        .build
        .deliver_later
    end
  end
end
