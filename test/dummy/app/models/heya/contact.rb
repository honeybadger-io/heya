module Heya
  class Contact < ApplicationRecord
    include Heya::Concerns::Models::Contact

    belongs_to :user, optional: true

    def email
      user&.email || read_attribute(:email)
    end
  end
end
