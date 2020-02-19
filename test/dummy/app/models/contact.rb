class Contact < ApplicationRecord
  store :traits, coder: JSON
end
