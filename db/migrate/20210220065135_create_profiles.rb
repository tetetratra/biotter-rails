class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.bigint :user_twitter_id
      t.string :user_screen_name, :limit => 1000
      t.string :user_name, :limit => 1000
      t.string :user_description, :limit => 1000
      t.binary :user_profile_image, :limit => 1.megabyte
      t.binary :user_profile_banner, :limit => 1.megabyte
      t.string :user_location, :limit => 1000
      t.string :user_url, :limit => 1000

      t.timestamps
    end
  end
end
