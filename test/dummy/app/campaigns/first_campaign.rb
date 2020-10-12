class FirstCampaign < Heya::Campaigns::Base
  step :one, subject: "First subject"
  step :two, subject: "Second subject"
  step :three, subject: "Third subject"
end
