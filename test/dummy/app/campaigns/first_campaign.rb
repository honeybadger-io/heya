class FirstCampaign < Heya::Campaigns::Base
  default contact_class: "Contact"

  step :one, subject: "First subject"
  step :two, subject: "Second subject"
end
