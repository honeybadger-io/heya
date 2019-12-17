class Heya::CampaignMailer < ApplicationMailer
  default from: "support@honeybadger.io"

  def build
    contact = params.fetch(:contact)

    step = params.fetch(:step)
    campaign = step.campaign

    instance_variable_set(:"@#{contact.model_name.element}", contact)

    mail(
      to: contact.email,
      subject: step.properties.fetch("subject"),
      template_path: "heya/campaign_mailer/#{campaign.name.underscore}",
      template_name: step.name.underscore
    )
  end
end
