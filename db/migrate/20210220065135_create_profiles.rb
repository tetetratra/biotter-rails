class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.integer :user_twitter_id
      t.string :user_screen_name
      t.string :user_name
      t.string :user_description
      t.binary :user_profile_image
      t.binary :user_profile_banner
      t.string :user_location
      t.string :user_url

      t.timestamps
    end
  end
end
