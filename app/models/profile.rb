class Profile < ApplicationRecord
  belongs_to :uesr

  paginates_per 20
end
