class AddImageHashToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :user_profile_image_hash, :string
    add_column :profiles, :user_profile_banner_hash, :string
  end
end
