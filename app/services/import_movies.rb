module ImportMovies
  # processes the upserting of data contained in a bulk import
  # @param [MovieImport] import
  def self.call(import)
    # mark the import as started
    import.update_column(:started_at, Time.now.utc)

    # loop each each import entry, processing each one
    import.entries.each_with_index do |entry, index|
      movie = Movie.find_or_initialize_by(id: entry["id"])
      movie.assign_attributes(entry)

      # if the movie fails to save, add it's errors to the import
      unless movie.save
        new_errors = movie.errors.full_messages.map do |error|
          "Error with entry ##{index + 1}: #{error}"
        end

        import.update_column(:entry_errors, Array(import.entry_errors) + new_errors)
      end
    end

    # mark the import as finished
    import.update_column(:finished_at, Time.now.utc)
  end
end
