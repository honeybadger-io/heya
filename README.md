# Heya 👋
![Test](https://github.com/honeybadger-io/heya/workflows/Test/badge.svg)
[![Gem Version](https://badge.fury.io/rb/heya.svg)](https://badge.fury.io/rb/heya)
[![Maintainability](https://api.codeclimate.com/v1/badges/a6416e63ffc426715857/maintainability)](https://codeclimate.com/github/honeybadger-io/heya/maintainability)

[![Twitter Follow](https://img.shields.io/twitter/follow/heyjoshwood?label=Follow%20Josh%20for%20dev%20updates&style=social)](https://mobile.twitter.com/heyjoshwood)

Heya is a campaign mailer for Rails. Think of it like ActionMailer, but for timed email sequences. It can also perform other actions like sending a text message.

## Getting started
Getting started with Heya is easy:

1. [Install the gem](#installing-the-heya-gem)
2. [Create a campaign](#creating-your-first-campaign)
3. [Run the scheduler](#running-the-scheduler)

### Installing the Heya gem
1. Add this line to your application's Gemfile:

  ```ruby
  gem "heya", github: "honeybadger-io/heya"
  ```

2. Then execute:

  ```bash
  bundle install
  rails generate heya:install
  rails db:migrate
  ```

  This will:

  1. Copy Heya's migration files to *db/migrate*
  1. Copy Heya's default initializer to *config/initializers/heya.rb*
  1. Create the file *app/campaigns/application_campaign.rb*
  1. Run local migrations

<details><summary>Note: Heya doesn't store a copy of your user data; instead, it reads from your existing <code>User</code> model (it never writes). If you have a different user model, change the <code>user_type</code> configuration option in <em>config/initializers/heya.rb</em>.</summary>

```ruby
# config/initializers/heya.rb
Heya.configure do |config|
  config.user_type = "MyUser"
end
```
</details>

### Creating your first campaign
1. Create a campaign:

  ```bash
  rails generate heya:campaign Onboarding welcome:0
  ```

2. Add a user to your campaign:

  ```ruby
  OnboardingCampaign.add(user)
  ```
  
  Add the following to your `User` model to send them the campaign
  when they first signup:
  
  ```ruby
  after_create_commit do
    OnboardingCampaign.add(self)
  end
  ```

### Running the scheduler
To start queuing emails, run the scheduler task periodically:

```bash
rails heya:scheduler
```

Heya uses ActiveJob to send emails in the background. Make sure your
ActiveJob backend is configured to process the `heya` queue. For example,
here's how you might start Sidekiq:

```sh
bundle exec sidekiq -q default -q heya
```

You can change Heya's default queue using the `queue` option:

```ruby
# app/campaigns/application_campaign.rb
class ApplicationCampaign < Heya::Campaigns::Base
  default queue: "custom"
end
```

### Bonus: tips for working with email in Rails

<details><summary>Use <a href="http://mailcatcher.me">MailCatcher</a> to see emails sent from your dev environment</summary>

```ruby
# config/environments/development.rb
Rails.application.configure do
  # ..

  # Use MailCatcher to inspect emails
  # http://mailcatcher.me
  # Usage:
  #   gem install mailcatcher
  #   mailcatcher
  #   # => Starting MailCatcher
  #   # => ==> smtp://127.0.0.1:1025
  #   # => ==> http://127.0.0.1:1080
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {host: "localhost", port: 1025}
end
```
</details>
<details><summary>Use <a href="https://github.com/codetriage/maildown">Maildown</a> to write your emails in Markdown</summary>

```sh
$ bundle add maildown
$ rails generate heya:campaign Onboarding welcome
      create  app/campaigns/application_campaign.rb
      create  app/campaigns/onboarding_campaign.rb
      create  app/views/heya/campaign_mailer/onboarding_campaign/welcome.md.erb
```

☝️ Notice how only one template was generated; Maildown automatically builds
the HTML and text variants from the markdown file.
</details>
<details><summary>Use <a href="https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails">ActionMailer::Preview</a> to preview emails as you write them</summary>

Heya's campaign generator generates previews for campaigns at
`(test|spec)/mailers/previews/*_campaign_preview.rb`. To see them, open
http://localhost:3000/rails/mailers/. If you didn't use the generator, you
can still build your own preview:

```ruby
# test/mailers/previews/onboarding_campaign_preview.rb
class OnboardingCampaignPreview < ActionMailer::Preview
  def welcome
    OnboardingCampaign.welcome(user)
  end

  private

  def user
    User.where(id: params[:user_id]).first || User.first
  end
end

```
</details>

## Configuration

You can use the following options to configure Heya (find this file in
*config/initializers/heya.rb*):

```ruby
Heya.configure do |config|
  # The name of the model you want to use with Heya.
  config.user_type = "User"

  # The default options to use when processing campaign steps.
  config.campaigns.default_options = {from: "user@example.com"}

  # Campaign priority. When a user is added to multiple campaigns, they are
  # sent in this order. Campaigns are sent in the order that the users were
  # added if no priority is configured.
  config.campaigns.priority = [
    "FirstCampaign",
    "SecondCampaign",
    "ThirdCampaign"
  ]
end
```

## Campaigns

### Creating campaigns
Heya stores campaigns in *app/campaigns/*, similar to how Rails stores mailers in *app/mailers/*. To create a campaign, run the following command inside your Rails project:

```bash
rails generate heya:campaign Onboarding first second third
```

This will:

1. Create the file *app/campaigns/onboarding_campaign.rb*
1. Create the directory *app/views/heya/campaign_mailer/onboarding_campaign/*
1. Create email templates inside of *app/views/heya/campaign_mailer/onboarding_campaign/*
1. Create an ActionMailer preview at *(test|spec)/mailers/previews/onboarding_campaign_preview.rb*

Here's the campaign that the above command generates:

```ruby
# app/campaigns/application_campaign.rb
class ApplicationCampaign < Heya::Campaigns::Base
  default from: "from@example.com"
end

# app/campaigns/onboarding_campaign.rb
class OnboardingCampaign < ApplicationCampaign
  step :first,
    subject: "First subject"

  step :second,
    subject: "Second subject"

  step :third,
    subject: "Third subject"
end
```

#### Steps
The `step` method defines a new step in the sequence. When you add a user to the campaign, Heya completes each step in the order that it appears.

The default time to wait between steps is *two days*, calculated from the time the user completed the previous step (or the time the user entered the campaign, in the case of the first step).

Each step has several options available (see the section [Creating messages](#creating-messages)).

### Creating messages
Messages are defined inside Heya campaigns using the `step` method. When you add a user to a campaign, Heya completes each step in the order that it appears.

**The most important part of each step is its name, which must be unique to the campaign.** The step's name is how Heya tracks which user has received which message, so it's essential that you don't change it after the campaign is active (if you do, Heya will assume it's a new message).

Here's an example of defining a message inside a campaign:

```ruby
class OnboardingCampaign < ApplicationCampaign
  step :welcome, wait: 1.day,
    subject: "Welcome to my app!"
end
```

In the above example, Heya will send a message named `:welcome` one day after a user enters the campaign, with the subject "Welcome to my app!"

The `wait` option tells Heya how long to wait before sending each message (the default is two days). There are a few scheduling options that you can customize for each step:

| Option Name | Default                           | Description                                              |
| :---------- | :-------------------------------- | :------------------------------------------------------- |
| `wait`      | `2.days`                          | The duration of time to wait before sending each message |
| `segment`   | `nil`                             | The segment who should receive the message               |
| `action`    | `Heya::Campaigns::Actions::Email` | The action to perform (usually sending an email)         |
| `queue`     | `"heya"`                          | The ActiveJob queue                                      |

Heya uses the following additional options to build the message itself:

| Option Name | Default      | Description                |
| :---------- | :----------- | :------------------------- |
| `subject`   | **required** | The email's subject        |
| `from`      | Heya default | The sender's email address |

You can change the default options using the `default` method at the top of the campaign. Heya applies default options to each step which doesn't supply its own:

```ruby
class OnboardingCampaign < ApplicationCampaign
  default wait: 1.day,
    queue: "onboarding",
    from: "support@example.com"

  # Will still be sent after one day from the
  # email address support@example.com
  step :welcome,
    subject: "Welcome to my app!"
end
```

#### Customizing email subjects for each user

The subject can be customized for each user by using a `lambda` instead of a `String`:

```ruby
# app/campaigns/onboarding_campaign.rb
class OnboardingCampaign < ApplicationCampaign
  step :welcome,
    subject: ->(user) { "Heya #{user.first_name}!" }
end
```

#### Translations for email subjects (I18n)

If you don't pass a `subject` to the `step` method, Heya will try to find it in your translations. The performed lookup will use the pattern `<campaign_scope>.<step_name>.subject` to construct the key.

```ruby
# app/campaigns/onboarding_campaign.rb
class OnboardingCampaign < ApplicationCampaign
  step :welcome
end
```

```yaml
# config/locales/en.yml
en:
  onboarding_campaign:
    welcome:
      subject: "Heya!"
```

To define parameters for interpolation, define a `#heya_attributes` method on your user model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def heya_attributes
    {
      first_name: name.split(" ").first
    }
  end
end
```

```yaml
# config/locales/en.yml
en:
  onboarding_campaign:
    welcome:
      subject: "Heya %{first_name}!"
```

### Custom Actions

You can override the default step behavior to perform custom actions by passing
a block to the `step` method:

```ruby
class OnboardingCampaign < ApplicationCampaign
  step :first_email,
    subject: "You're about to receive a txt"

  step :sms do |user|
    SMS.new(to: user.cell, body: "Hi, #{user.first_name}!").deliver
  end

  step :second_email,
    subject: "Did you get it?"
end
```

Step blocks receive two optional arguments: `user` and `step`, and are processed
in a background job alongside other actions.

### Adding users to campaigns
Heya leaves *when* to add users to campaigns completely up to you; here's how to add a user to a campaign from anywhere in your app:

```ruby
OnboardingCampaign.add(user)
```

To remove a user from a campaign:

```ruby
OnboardingCampaign.remove(user)
```

Adding users to campaigns from Rails opens up some interesting automation possibilities--for instance, you can start or stop campaigns from `ActiveRecord` callbacks, or in response to other events that you're already tracking in your application. [See here for a list of ideas](#).

Because Heya stacks campaigns by default (meaning it will never send more than one at a time), you can also queue up several campaigns for a user, and they'll receive them in order:

```ruby
WelcomeCampaign.add(user)
OnboardingCampaign.add(user)
EvergreenCampaign.add(user)
```
*Note: you can customize the priority of campaigns via Heya's configuration.*

If you want to send a user two campaigns simultaneously,  you can do so with the `concurrent` option:

```ruby
FlashSaleCampaign.add(user, concurrent: true)
```

When you remove a user from a campaign and add them back later, they'll continue where they left off. If you want them to start over from the beginning, use the `restart` option:

```ruby
TrialConversionCampaign.add(user, restart: true)
```

#### Automation ideas

Using `ActiveSupport::Notifications` to respond to lifecycle events (which could be sent from your Stripe controller, for instance):

```ruby
ActiveSupport::Notifications.subscribe("user.trial_will_end") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    if event.payload[:user_id]
      user = User.find(event.payload[:user_id])
      TrialConversionCampaign.add(user, restart: true)
    end
end
```

Scheduling campaigns in `ActiveRecord` callbacks:

```ruby
class User < ApplicationRecord
  after_create_commit do
    WelcomeCampaign.add(self)
    OnboardingCampaign.add(self)
    EvergreenCampaign.add(user)
  end
end
```

### Customizing who gets what
Heya can send individual messages to certain users using the `segment` option. The following campaign will send the message to inactive users--active users will be skipped:

```ruby
class ActivationCampaign < ApplicationCampaign
  step :activate, segment: ->(user) { user.inactive? }
end
```

When you're checking the value of a single method on the user, the segment can be simplified to the symbol version:

```ruby
class ActivationCampaign < ApplicationCampaign
  step :activate, segment: :inactive?
end
```

#### Segmenting specific campaigns
You can also narrow entire campaigns to certain users using the `segment` method. For instance, if you have a campaign with a specific goal such as performing an action in your app, then you can send the campaign only to the users who haven't performed the action:

```ruby
class UpgradeCampaign < ApplicationCampaign
  segment { |u| !u.upgraded? }

  step :one
  step :two
  step :three
end
```

If they upgrade half way through the campaign, Heya will stop sending messages and remove them from the campaign.

Likewise, you can require that users meet conditions to continue receiving a campaign. Here's a campaign which sends messages only to trial users--non-trial users will be removed from the campaign:

```ruby
class TrialCampaign < ApplicationCampaign
  segment :trial?

  step :one
  step :two
  step :three
end
```

#### Segmenting all campaigns
Heya campaigns inherit options from parent campaigns. For example, to make sure
unsubscribed users never receive an email from Heya, create a `segment` in the
`ApplicationCampaign`, and then have all other campaigns inherit from it:

```ruby
class ApplicationCampaign < Heya::Campaigns::Base
  segment :subscribed?
end
```

### Handling exceptions

Heya campaigns are [rescuable](https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html).
Use the `rescue_from` method to handle exceptions in campaigns:

```ruby
class OnboardingCampaign < ApplicationCampaign
  rescue_from Postmark::InactiveRecipientError, with: :log_error

  private

  def log_error(error)
    Rails.logger.error("Got Heya error: #{error}")
  end
end
```

See the
[Rails documentation](https://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from)
for additional details.

### Campaigns FAQ
**What happens when:**
<details><summary>I reorder messages in an active campaign?</summary>

Heya sends the next *unsent* message *after the last message the user received*. When you move a message, the users who last received it will be moved with it, and continue from that point in the campaign. Heya skips messages which the user has already seen.
</details>

<details><summary>I add a message to an active campaign?</summary>

Users who have already received a message *after* the new message will *not* receive the message.
</details>

<details><summary>I remove a message from an active campaign?</summary>

Users who last received the message will be moved up to the previously received message, and continue from that point in the campaign. Heya skips messages which the user has already seen.
</details>

<details><summary>I rename a message in an active campaign?</summary>

**Renaming a message is equivalent to removing the message and adding a new one.** Users who are waiting to receive an earlier message in the campaign will receive the new message. Users who last received the old message will also receive the new one since it has replaced its position in the campaign.
</details>

<details><summary>A user skips a message based on its conditions?</summary>

Heya waits the defined wait time for every message in the campaign. If a user doesn't match the conditions, Heya skips it. If the *next* message's wait time is less than or equal to the skipped message's, it sends it immediately. If the next wait period is longer, it sends it after the new wait time has elapsed.
</details>

<details><summary>I delete an active campaign?</summary>

Heya will immediately stop sending the campaign; the campaign's data will remain until you manually delete it. If you restore the file before deleting the campaign's data, Heya will resume sending the campaign.
</details>

<details><summary>I add a user to multiple campaigns?</summary>

By default, Heya sends each user one campaign at a time. It determines the order of campaigns using the campaign `priority`. When you add a user to a higher priority campaign, the new campaign will begin immediately. Once completed, the next highest priority campaign will resume sending.

To send a campaign concurrent to other active campaigns, use the `concurrent` option.
</details>

<details><summary>I add a user to a campaign they already completed?</summary>

When you add a user to a campaign that they previously completed, Heya sends new messages which were added *to the end of the campaign*. Skipped messages will *not* be sent. To resend all messages, use the `restart` option.
</details>

**Less frequently asked questions:**
<details><summary>Can the same message be delivered twice?</summary>

Nope, not without restarting the campaign using the `restart` option (which will resend all the messages).
</details>

<details><summary>Can the same campaign be sent twice?</summary>

Yep. When you add a user to a campaign that they previously completed, Heya sends new messages which were added *to the end of the campaign*. Skipped messages will *not* be sent. To resend all messages, use the `restart` option.
</details>

<details><summary>Can I resend a campaign to a user?</summary>

Yep. Use the `restart` option to resend a campaign to a user (if they are already in the campaign, the campaign will start over from the beginning).
</details>

<details><summary>Can I send a user two campaigns at the same time?</summary>

Yep. By default, Heya sends campaigns ain order of `priority`. Use the `concurrent` option to send campaigns concurrently.
</details>

## Roadmap
See [here](https://github.com/honeybadger-io/heya/projects/1) for things we're
considering adding to Heya.

## Contributing
1. Fork it.
2. Create a topic branch `git checkout -b my_branch`
3. Make your changes and add an entry to the [CHANGELOG](CHANGELOG.md).
4. Commit your changes `git commit -am "Boom"`
5. Push to your branch `git push origin my_branch`
6. Send a [pull request](https://github.com/honeybadger-io/heya/pulls)

## License
This package is free to use for noncommercial purposes and for commercial purposes during a trial period under the terms of the [Prosperity Public License](LICENSE).
