class Contact < ApplicationRecord
  include Heya::Concerns::Models::User
  store :traits, coder: JSON
end
