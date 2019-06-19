class Heya::CampaignMailer < ApplicationMailer
  default from: "badgers@honeybadger.io"

  def build
    @contact = params.fetch(:contact)
    @message = params.fetch(:message)
    @campaign = @message.campaign

    mail(
      to: @contact.email,
      subject: @message.properties.fetch("subject"),
      template_path: "heya/campaign_mailer/#{@campaign.name.underscore}",
      template_name: @message.name.underscore
    )
  end
end
