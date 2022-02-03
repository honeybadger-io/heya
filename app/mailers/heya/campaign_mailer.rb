module Heya
  class CampaignMailer < ApplicationMailer
    DEFAULT_LAYOUT = "heya/campaign_mailer"
    layout -> { params.fetch(:step).params.fetch("layout", DEFAULT_LAYOUT) }
    include Rails.application.routes.url_helpers

    def build
      user = params.fetch(:user)
      step = params.fetch(:step)

      campaign_name = step.campaign_name.underscore
      step_name = step.name.underscore

      from = step.params.fetch("from")
      bcc = step.params.fetch("bcc", nil)
      reply_to = step.params.fetch("reply_to", nil)

      subject = step.params.fetch("subject") {
        I18n.t("#{campaign_name}.#{step_name}.subject", **attributes_for(user))
      }
      subject = subject.call(user) if subject.respond_to?(:call)

      instance_variable_set(:"@#{user.model_name.element}", user)
      instance_variable_set(:@campaign_name, campaign_name)

      mail(
        from: from,
        bcc: bcc,
        reply_to: reply_to,
        to: to_address(user, step),
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

    def to_address(user, step)
      return step.params["to"].call(user) if step.params["to"].respond_to?(:call)

      if user.respond_to?(:first_name)
        email_address_with_name(user.email, user.first_name)
      elsif user.respond_to?(:name)
        email_address_with_name(user.email, user.name)
      else
        user.email
      end
    end
  end
end
