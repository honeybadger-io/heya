class FirstCampaign < Heya::Campaigns::Base
  contact_type "Contact"

  step :one, subject: "First subject"
  step :two, subject: "Second subject"
end
