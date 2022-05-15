class MovieImport < ApplicationRecord
  # callbacks
  after_commit :trigger_import, on: :create

  private

  def trigger_import
    ImportMovies.call(self)
  end
end
