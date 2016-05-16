class CreateGdrives < ActiveRecord::Migration
  def up
    create_table :gdrives do |t|

      t.text :access_token
      t.string :app_folder_id

    end

  end

  def down
    drop_table :gdrives
  end
end
