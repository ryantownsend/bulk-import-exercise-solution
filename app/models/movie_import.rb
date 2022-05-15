class MovieImport < ApplicationRecord
  # attributes
  # we tell Rails to treat the entries as text instead of JSONB, this way it
  # won't perform expensive typecasting/parsing between Ruby objects and the
  # raw JSON string
  attribute :entries, :text

  # callbacks
  after_commit :trigger_import, on: :create

  private

  def trigger_import
    MovieImportJob.perform_later(id)
  end
end
