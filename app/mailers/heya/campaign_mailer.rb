module Heya
  class CampaignMailer < ApplicationMailer
    layout "heya/campaign_mailer"

    def build
      user = params.fetch(:user)
      step = params.fetch(:step)

      campaign_name = step.campaign_name.underscore
      step_name = step.name.underscore

      from = step.params.fetch("from")
      reply_to = step.params.fetch("reply_to", nil)

      subject = step.params.fetch("subject") {
        I18n.t("#{campaign_name}.#{step_name}.subject", **attributes_for(user))
      }
      subject = subject.call(user) if subject.respond_to?(:call)

      instance_variable_set(:"@#{user.model_name.element}", user)
      instance_variable_set(:@campaign_name, campaign_name)

      mail(
        from: from,
        reply_to: reply_to,
        to: user.email,
        subject: subject,
        template_path: "heya/campaign_mailer/#{campaign_name}",
        template_name: step_name
      )
    end

    protected

    def attributes_for(user)
      if user.respond_to?(:heya_attributes)
        user.heya_attributes.symbolize_keys
      else
        {}
      end
    end

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
