# frozen_string_literal: true

# we've moved to ActionController::Metal as this doesn't trigger the middleware
# for parsing JSON into an object, allowing us to push the unparsed JSON
# straight into ActiveRecord, reducing CPU and memory overhead
class MovieImportsController < ActionController::Metal
  # we have to include some modules to keep our clean JSON response rendering
  include AbstractController::Rendering
  include ActionController::Rendering
  include ActionController::Renderers
  use_renderers :json

  def create
    @movie_import = MovieImport.create(entries: movie_import_entries)

    if @movie_import.persisted?
      render json: { id: @movie_import.id }, status: :created
    else
      render json: { errors: @movie_import.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::StatementInvalid => e
    if e.cause.is_a?(PG::InvalidTextRepresentation)
      render json: { errors: ["Entries contains invalid JSON"] }, status: :unprocessable_entity
    else
      raise e
    end
  end

  private

  def movie_import_entries
    # we've replaced accessing the JSON via strong parameters to using the raw
    # post body from the request - be aware this may have security implications
    # in your own code
    request.raw_post
  end
end
