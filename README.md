# Heya 👋
[![CircleCI](https://circleci.com/gh/honeybadger-io/heya.svg?style=svg&circle-token=41341cd6f508a899e10bb09b9c9e45941bfb6944)](https://circleci.com/gh/honeybadger-io/heya)

Heya is a customer communication and automation framework for Rails. The purpose
of this project is to replace Honeybadger's usage of Intercom and Drip.

## Roadmap
For the time being, we could use [ahoy](https://github.com/ankane/ahoy) for web
analytics, event tracking, email analytics, and subscribes/unsubscribes. I'd
like to take advantage of the existing Rails ecosystem as much as
possible--i.e., let's not reinvent the wheel unless we have a good reason to do
so.

### MVP (0.0.x)
The initial goal of this project is fairly limited:

- [ ] Replicate Intercom's campaign logic for email campaigns via a Ruby API
- [ ] Build a basic reporting UI

### Version 0.1
- [ ] A decent web UI, with ability to create and manage:
  - [ ] Segments
  - [ ] Campaigns (maintaining support for Ruby API)
  - [ ] Broadcasts

### The Future
Here are some future things we may consider:

- [ ] Event handling (Intercom/Drip)
- [ ] Automation workflows (Drip)
- [ ] Automation rules (Drip)
- [ ] Customer support inbox/integration (Intercom)
- [ ] Live chat widget/integration (Intercom)
- [ ] Additional actions (pusher, twilio, etc.)
- [ ] Personalization framework[^1]

☝️ many of these could be features of this engine, or new engines/projects which
play nice (similar to the ahoy ecosystem). I.e.: heya-campaigns,
heya-automation, heya-personalization, heya-support, heya-chat, etc.

[^1]: Imagine being able to personalize your app and marketing site together,
using Ruby. That could be an argument to host your marketing site with your app
(like the old days), or perhaps with
[high_voltage](https://github.com/thoughtbot/high_voltage).

## Usage
1. Create a campaign:
    ```ruby
    # app/campaigns/trial_onboarding_campaign.rb
    class TrialOnboardingCampaign < Heya::Campaigns::Base
      default wait: 2.days

      step :one,   subject: 'First email subject',  wait: 0.days
      step :two,   subject: 'Second email subject', segment: -> { trialing.installed_project }
      step :three, subject: 'Third email subject'
    end
    ```

2. Create campaign email templates (i.e. using
   [maildown](https://github.com/schneems/maildown)):
    - `app/views/heya/campaign_mailer/trial_onboarding_campaign/one.md.erb`
    - `app/views/heya/campaign_mailer/trial_onboarding_campaign/two.md.erb`
    - `app/views/heya/campaign_mailer/trial_onboarding_campaign/three.md.erb`
    - etc.

3. Add a contact to a campaign:
    ```ruby
    TrialOnboardingCampaign.add(contact)
    ```

4. Run the scheduler periodically:
    ```ruby
    rails heya:scheduler
    ```

## Installation
1. Clone this repo in your project's parent directory:
```bash
git clone https://github.com/honeybadger-io/heya.git
```

2. Add this line to your application's Gemfile:
```ruby
gem 'heya', path: '../heya'
```

4. Then execute:
```bash
bundle
rails heya:install:migrations db:migrate
```

## Contributing
TODO: Contribution directions go here.

## License
The gem is copyright 2019 Honeybadger Industries LLC. All rights reserved.

(TODO: Figure out the license.)
