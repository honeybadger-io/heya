# Heya 👋

Heya is a customer communication and automation framework for Ruby on Rails. It's as robust as the hosted alternatives, without the integration and compliance nightmare.

## Why Heya?
Imagine onboarding and engaging your users with full access to their data, without maintaining a single 3rd-party integration or stressing over compliance. That's Heya: a new way to email your users.

Heya lives inside your Rails app, giving you full access to your customer data with the power of Ruby and Rails for building automated email campaigns.

If you've ever used 3rd-party email or marketing platforms, you've felt the pain of integrating, syncing customer data, and maintaining complex logic and rules--all of which is unnecessary in Heya.

Email automation becomes startlingly simple when your application framework *is* your automation tool.

## Who is Heya for?
- SaaS developers who are marketers at heart
- SaaS marketers who are developers at heart
- Development and marketing teams who work closely together

## Stuff we believe
- You should avoid duplicating customer data
- Segments should live as close to home as possible
  - So should automation
  - So should content
- Code is for everyone, not just developers
- Heya is the best way to engage your users

## Getting started
Getting started with Heya is easy:

1. [Install the gem](#installing-the-heya-gem)
2. [Create a campaign](#creating-your-first-campaign)
3. [Run the scheduler](#running-the-scheduler)

### Installing the Heya gem
1. Clone this repo in your project's parent directory:

  ```bash
  git clone https://github.com/honeybadger-io/heya.git
  ```

2. Add this line to your application's Gemfile:

  ```ruby
  gem "heya", path: "../heya"
  ```

3. Then execute:

  ```bash
  bundle install
  rails generate heya:install
  rails db:migrate
  ```

  This will do 3 things:

  1. Copy Heya's migration files to *db/migrate*
  2. Copy Heya's default initializer to *config/initializers/heya.rb*
  3. Run local migrations

<details><summary>Note: Heya doesn't store a copy of your user data; instead, it reads from your existing `User` model (it never writes). If you have a different user model, change the `user_type` configuration option in *config/initializers/heya.rb*.</summary>

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
  rails generate heya:campaign Onboarding welcome
  ```

2. Add a user to your campaign:

  ```ruby
  OnboardingCampaign.add(user)
  ```

### Running the scheduler
To start sending emails, run the scheduler periodically:

```bash
rails heya:scheduler
```

## Campaigns

### Creating campaigns
Heya stores campaigns in *app/campaigns/*, similar to how Rails stores mailers in *app/mailers/*. To create a campaign, run the following command inside your Rails project:

```bash
rails generate heya:campaign Onboarding first second third
```

This will do three things:

- Create the file *app/campaigns/onboarding_campaign.rb*
- Create the directory *app/views/heya/campaign_mailer/onboarding_campaign/*
- Create email templates inside of *app/views/heya/campaign_mailer/onboarding_campaign/*

Here's the campaign that the above command generates:

```ruby
class OnboardingCampaign < Heya::Campaigns::Base
  step :first,
    subject: "First subject",

  step :second,
    subject: "Second subject",

  step :third,
    subject: "Third subject"
end
```

#### Steps
The `step` command defines a new step in the sequence. When you add a user to the campaign, Heya completes each step in the order that it appears.

The default time to wait between steps is *two days*, calculated from the time the user completed the previous step (or the time the user entered the campaign, in the case of the first step).

Each step has several options available (see the section [Creating messages](#)).

### Creating messages
Messages are defined inside Heya campaigns using the `step` method. When you add a user to a campaign, Heya completes each step in the order that it appears.

**The most important part of each step is its name, which must be unique to the campaign.** The step's name is how Heya tracks which user has received which message, so it's essential that you don't change it after the campaign is active (if you do, Heya will assume it's a new message).

Here's an example of defining a message inside a campaign:

```ruby
class OnboardingCampaign < Heya::Campaigns::Base
  step :welcome, wait: 1.day,
    subject: "Welcome to my app!"
end
```

In the above example, Heya will send a message named `:welcome` one day after a user enters the campaign, with the subject "Welcome to my app!"

The `wait` option tells Heya how long to wait before sending each message (the default is two days). There are a few scheduling options that you can customize for each step:

| Option Name | Default | Description  |
|:--|:--|:--|
| `wait`  | `2.days` | The duration of time to wait before sending each message |
| `segment`  | `nil` | The segment who should receive the message |
| `action` | `Heya::Actions::Email` | The action to perform (usually sending an email) |

Heya uses the following additional options to build the message itself:

| Option Name | Default | Description  |
|:--|:--|:--|
| `subject`  | **required** | The email's subject |
| `from`  | Heya default | The sender's email address |

You can change the default options using the `default` method at the top of the campaign. Heya applies default options to each step which doesn't supply its own:

```ruby
class OnboardingCampaign < Heya::Campaigns::Base
  default wait: 1.day,
    from: "support@example.com"

  # Will still be sent after one day from the
  # email address support@example.com
  step :welcome,
    subject: "Welcome to my app!"
end
```

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
class ActivationCampaign < Heya::Campaigns::Base
  step :activate, segment: ->(user) { user.inactive? }
end
```

When you're checking the value of a single method on the user, the segment can be simplified to the symbol version:

```ruby
class ActivationCampaign < Heya::Campaigns::Base
  step :activate, segment: :inactive?
end
```

#### Segmenting specific campaigns
You can also narrow entire campaigns to certain users using the `segment` method. For instance, if you have a campaign with a specific goal such as performing an action in your app, then you can send the campaign only to the users who haven't performed the action:

```ruby
class UpgradeCampaign < Heya::Campaigns::Base
  segment { |u| !u.upgraded? }

  step :one
  step :two
  step :three
end
```

If they upgrade half way through the campaign, Heya will stop sending messages and remove them from the campaign.

Likewise, you can require that users meet conditions to continue receiving a campaign. Here's a campaign which sends messages only to trial users--non-trial users will be removed from the campaign:

```ruby
class TrialCampaign < Heya::Campaigns::Base
  segment :trial?

  step :one
  step :two
  step :three
end
```

#### Segmenting all campaigns
Finally, there is a *global* option to segment users called `default_segment`. **All users must match the default segment to receive messages from Heya**.

The default segment must be declared once, on your `User` model. For example, you can use `default_segment` to allow users to opt out of emails:

```ruby
class User < ApplicationRecord
  default_segment :subscribed_to_emails?
end
```

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
For the time being, we could use [ahoy](https://github.com/ankane/ahoy) for web analytics, event tracking, email analytics, and subscribes/unsubscribes. I'd like to take advantage of the existing Rails ecosystem as much as possible--i.e., let's not reinvent the wheel unless we have a good reason to do so.

### MVP (0.0.x)
We need the following features to replace Intercom:

- [ ] Campaigns
- [ ] Broadcasts
- [ ] Segments (or at least some way to send broadcasts to groups of users)

See [here](https://github.com/honeybadger-io/heya/projects/1) for current MVP
status.

### Version 0.1
[TBD](https://github.com/honeybadger-io/heya/issues?q=is%3Aopen+is%3Aissue+label%3Aidea)

## Contributing
1. Fork it.
2. Create a topic branch `git checkout -b my_branch`
3. Make your changes and add an entry to the [CHANGELOG](CHANGELOG.md).
4. Commit your changes `git commit -am "Boom"`
5. Push to your branch `git push origin my_branch`
6. Send a [pull request](https://github.com/honeybadger-io/heya/pulls)

## License
This package is free to use for noncommercial purposes and for commercial purposes during a trial period under the terms of the [Prosperity Public License](./LICENSE).
