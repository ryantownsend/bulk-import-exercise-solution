class AddEntryCountToMovieImportsTable < ActiveRecord::Migration[7.0]
  def change
    change_table :movie_imports do |t|
      t.virtual :entry_count, type: :integer, as: "jsonb_array_length(entries)", stored: true, null: false
    end
  end
end
