class CreateAddFieldToCores < ActiveRecord::Migration
  def up
    add_column :attachments, :gdrive_id, :string
    add_column :issues, :gdrive_id, :string
    add_column :projects, :gdrive_id, :string
  end

  def down
    remove_column :attachments, :gdrive_id
    remove_column :issues, :gdrive_id
    remove_column :projects, :gdrive_id
  end
end
