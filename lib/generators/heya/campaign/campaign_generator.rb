# frozen_string_literal: true

class Heya::CampaignGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :steps, type: :array, default: []

  def copy_campaign_template
    application_campaign = "app/campaigns/application_campaign.rb"
    unless File.exist?(application_campaign)
      template File.expand_path("../install/templates/application_campaign.rb", __dir__), application_campaign
    end
    template "campaign.rb", "app/campaigns/#{file_name.underscore}_campaign.rb"
  end

  def copy_view_templates
    selection =
      if defined?(Maildown)
        puts <<~MSG
          What type of views would you like to generate?
            1. Multipart (text/html)
            2. Maildown (markdown)
        MSG

        ask(">")
      else
        "1"
      end

    template_method =
      case selection
      when "1"
        method(:action_mailer_template)
      when "2"
        method(:maildown_template)
      else
        abort "Error: must be a number [1-2]"
      end

    steps.each do |step|
      step, _wait = step.split(":")
      @step = step
      template_method.call(step)
    end
  end

  def copy_test_templates
    if preview_path
      template "preview.rb", preview_path.join("#{file_name.underscore}_campaign_preview.rb")
    end
  end

  private

  def action_mailer_template(step)
    template "message.text.erb", "app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.text.erb"
    template "message.html.erb", "app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.html.erb"
  end

  def maildown_template(step)
    template "message.md.erb", "app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.md.erb"
  end

  def preview_path
    @preview_path ||= begin
      preview_path = if ActionMailer::Base.respond_to?(:preview_paths)
        # Rails 7.1+
        ActionMailer::Base.preview_paths.first
      else
        # Rails < 7.1
        ActionMailer::Base.preview_path
      end

      Pathname(preview_path).sub(Rails.root.to_s, ".") if preview_path
    end
  end
end
