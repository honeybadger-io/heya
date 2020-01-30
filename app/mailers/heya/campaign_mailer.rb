class Heya::CampaignMailer < ApplicationMailer
  layout "heya/campaign_mailer"

  def build
    user = params.fetch(:user)

    step = params.fetch(:step)
    campaign = step.campaign

    instance_variable_set(:"@#{user.model_name.element}", user)

    mail(
      from: step.from,
      to: user.email,
      subject: step.properties.fetch("subject"),
      template_path: "heya/campaign_mailer/#{campaign.name.underscore}",
      template_name: step.name.underscore
    )
  end
end
