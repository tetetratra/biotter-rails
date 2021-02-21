class DeleteColumnFromProfile < ActiveRecord::Migration[6.0]
  def change
    remove_column :profiles, :user_profile_image, :binary
    remove_column :profiles, :user_profile_banner, :binary
  end
end
