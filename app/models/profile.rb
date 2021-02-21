class Profile < ApplicationRecord
  has_one_attached :user_profile_image
  has_one_attached :user_profile_banner

  paginates_per 20
end
