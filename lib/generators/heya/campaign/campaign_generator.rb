class Heya::CampaignGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :steps, type: :array, default: []

  def copy_campaign_template
    template "campaign.rb", "app/campaigns/#{file_name.underscore}_campaign.rb"
  end

  def copy_view_templates
    steps.each do |step|
      @step = step
      template "message.text.erb", "app/views/heya/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.text.erb"
      template "message.html.erb", "app/views/heya/#{file_name.underscore}_campaign/#{step.underscore.to_sym}.html.erb"
    end
  end
end
