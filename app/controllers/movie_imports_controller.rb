# frozen_string_literal: true

class MovieImportsController < ApplicationController
  def create
    @movie_import = MovieImport.create(entries: movie_import_entries)

    if @movie_import.persisted?
      render json: { id: @movie_import.id }, status: :created
    else
      render json: { errors: @movie_import.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActionDispatch::Http::Parameters::ParseError
    render json: { errors: ["Entries contains invalid JSON"] }, status: :unprocessable_entity
  end

  private

  def movie_import_entries
    params.permit("_json": [:id, :title, :description, :rating, :published, subscriber_emails: []])["_json"]
  end
end
