# frozen_string_literal: true

require "active_record/relation"

module Heya
  module ActiveRecordRelationExtension
    TABLE_REGEXP = /heya_steps/

    def build_arel(...) # forward all params. Handles differences between 7.1 -> 7.2
      arel = super

      if table_name == "heya_campaign_memberships" && arel.to_sql =~ TABLE_REGEXP
        # https://www.postgresql.org/docs/9.4/queries-values.html
        values = Heya
          .campaigns.reduce([]) { |steps, campaign| steps | campaign.steps }
          .map { |step|
            ActiveRecord::Base.sanitize_sql_array(
              ["(?, ?)", step.gid, step.wait.to_i]
            )
          }

        if values.any?
          relation = Arel::Nodes::SqlLiteral.new("(SELECT * FROM (VALUES #{values.join(", ")}) AS heya_steps (gid,wait))")

          # Rails 7.1 added Arel::Nodes::Cte. Rails 8.2 changed Arel::Table.new to
          # take the name as a keyword argument, so avoid it where Cte is available.
          cte = if defined?(Arel::Nodes::Cte)
            Arel::Nodes::Cte.new(:heya_steps, relation)
          else
            Arel::Nodes::As.new(Arel::Table.new(:heya_steps), relation)
          end

          arel.with(cte)
        end
      end

      arel
    end
  end

  ActiveRecord::Relation.prepend(ActiveRecordRelationExtension)
end
