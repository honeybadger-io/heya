module Heya
  module Actions
    Email = ->(user:, step:) do
      CampaignMailer
        .with(user: user, step: step)
        .build
    end
  end
end
