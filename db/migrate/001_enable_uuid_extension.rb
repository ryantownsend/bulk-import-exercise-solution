class EnableUuidExtension < ActiveRecord::Migration[7.0]
  def change
    # we'll be using UUIDs for our movie primary key
    enable_extension "uuid-ossp"
  end
end
