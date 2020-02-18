module Heya
  class CampaignMailer < ApplicationMailer
    layout "heya/campaign_mailer"

    def build
      user = params.fetch(:user)
      step = params.fetch(:step)
      campaign = step.campaign
      from = step.params.fetch("from", Heya.config.from)
      subject = step.params.fetch("subject")

      instance_variable_set(:"@#{user.model_name.element}", user)

      mail(
        from: from,
        to: user.email,
        subject: subject,
        template_path: "heya/campaign_mailer/#{campaign.name.underscore}",
        template_name: step.name.underscore
      )
    end
  end
end
