class MovieImportJob < ApplicationJob
  queue_as :default

  def perform(movie_import_id)
    import = MovieImport.find(movie_import_id)
    ImportMovies.call(import)
  end
end
