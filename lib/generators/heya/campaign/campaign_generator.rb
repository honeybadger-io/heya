# frozen_string_literal: true

class Heya::CampaignGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :steps, type: :array, default: []

  def copy_campaign_template
    template "application_campaign.rb", root_path.join("app/campaigns/application_campaign.rb")
    template "campaign.rb", root_path.join("app/campaigns/#{file_name.underscore}_campaign.rb")
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
      @step = step
      template_method.call(step)
    end
  end

  def copy_test_templates
    template "preview.rb", preview_path.join("#{file_name.underscore}_campaign_preview.rb")
  end

  private

  def action_mailer_template(step)
    template "message.text.erb", root_path.join("app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.text.erb")
    template "message.html.erb", root_path.join("app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.html.erb")
  end

  def maildown_template(step)
    template "message.md.erb", root_path.join("app/views/heya/campaign_mailer/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.md.erb")
  end

  def root_path
    Rails.root
  end

  def preview_path
    root_path.join(ActionMailer::Base.preview_path)
  end
end
