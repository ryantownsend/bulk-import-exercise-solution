class CreateMovieNotificationsTable < ActiveRecord::Migration[7.0]
  def change
    # this table stores who has been notified about each movie update - it's a
    # pretty naive feature, but is helpful in demonstrating the optimisations
    create_table :movie_notifications, id: :uuid do |t|
      # the email this notification was sent to
      t.text :email, null: false
      # the movie it was for
      t.references :movie, type: :uuid, null: false, foreign_key: true, index: true
      # and just a created_at timestamp as these are immutable
      t.datetime :created_at, null: false
    end
  end
end
