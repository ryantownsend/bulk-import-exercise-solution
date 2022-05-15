class EventStream < ActiveSupport::CurrentAttributes
  attribute :updated_movie_ids

  # effectively a pre- and post- request/job callback
  before_reset do
    if updated_movie_ids&.any?
      # enqueue a job to process any updated movies
      MovieNotificationJob.perform_later(updated_movie_ids)
    end
  end

  # stores when any given movie has been updated
  def movie_updated(movie_id)
    self.updated_movie_ids ||= []
    self.updated_movie_ids << movie_id
  end
end
