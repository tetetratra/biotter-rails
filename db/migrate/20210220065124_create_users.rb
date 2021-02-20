class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.bigint :user_twitter_id

      t.timestamps
    end
  end
end
