# Upgrading Heya

## Unreleased
Campaign memberships gained a `halt` column. If you're upgrading an existing
install, generate the migration so the timestamp and migration version match
your app:

```
bin/rails generate migration AddHaltToHeyaCampaignMemberships halt:boolean
```

Then add the null constraint and default to the generated `add_column` line:

```
add_column :heya_campaign_memberships, :halt, :boolean, null: false, default: false
```

Defaulting to `false` preserves the existing behavior: users whose segment stops
matching have their messages skipped and stay in the campaign. See "Ending a
campaign early" in the [README](./README.md#ending-a-campaign-early) to opt in.

## 0.4.0
If you're upgrading from Heya `< 0.4`, you will need the following migration:

```
class AddStepGidToHeyaCampaignMemberships < ActiveRecord::Migration[6.0]
  def up
    add_column :heya_campaign_memberships, :step_gid, :string
    Heya::CampaignMembership.migrate_next_step!
    change_column :heya_campaign_memberships, :step_gid, :string, null: false
  end

  def down
    remove_column :heya_campaign_memberships, :step_gid, :string
  end
end
```

See [CHANGELOG.md](./CHANGELOG.md) for more info.
