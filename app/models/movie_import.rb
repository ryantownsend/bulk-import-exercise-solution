class MovieImport < ApplicationRecord
  # callbacks
  after_commit :trigger_import, on: :create

  private

  def trigger_import
    MovieImportJob.perform_later(id)
  end
end
