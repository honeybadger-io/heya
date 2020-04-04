module Heya
  class CampaignMailer < ApplicationMailer
    layout "heya/campaign_mailer"

    def build
      user = params.fetch(:user)
      step = params.fetch(:step)
      campaign = step.campaign
      from = step.params.fetch("from")
      reply_to = step.params.fetch("reply_to", nil)
      subject = step.params.fetch("subject")

      instance_variable_set(:"@#{user.model_name.element}", user)

      mail(
        from: from,
        reply_to: reply_to,
        to: user.email,
        subject: subject,
        template_path: "heya/campaign_mailer/#{campaign.name.underscore}",
        template_name: step.name.underscore
      )
    end

    protected

    def _prefixes
      @_prefixes_with_campaign_path ||= begin
        if params.is_a?(Hash) && (campaign_name = params[:step]&.campaign&.name&.underscore)
          super | ["heya/campaign_mailer/#{campaign_name}"]
        else
          super
        end
      end
    end
  end
end
