class CreateMovieImportsTable < ActiveRecord::Migration[7.0]
  def change
    # this table stores our imports that are queued for processing
    create_table :movie_imports, id: :uuid do |t|
      # our entries will store each movie we want to import
      t.jsonb :entries, null: false
      # our errors will store any validation failures
      t.text :entry_errors, array: true, null: false, default: []
      # we'll have the standard Rails timestamps
      t.timestamps
      # and two more for logging the exact duration of the import
      t.datetime :started_at
      t.datetime :finished_at
    end
  end
end
