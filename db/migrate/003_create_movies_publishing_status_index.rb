class CreateMoviesPublishingStatusIndex < ActiveRecord::Migration[7.0]
  def change
    # if we were publishing a website from this database, we'd feasibly need at
    # least an index on the `publishing_status` column so we can filter to just
    # published movies
    add_index :movies, :publishing_status
  end
end
