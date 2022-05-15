class MovieImportJob < ApplicationJob
  queue_as :default

  def perform(movie_import_id)
    ImportMovies.call(movie_import_id)
  end
end
