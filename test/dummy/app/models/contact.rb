class Contact < ApplicationRecord
  store :traits, coder: JSON

  def heya_attributes
    traits
  end
end
