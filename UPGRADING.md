# Upgrading Heya

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
