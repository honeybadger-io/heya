module Heya
  module Actions
    Email = ->(user:, step:) do
      CampaignMailer
        .with(user: user, step: step)
        .build
        .deliver_later
    end
  end
end
