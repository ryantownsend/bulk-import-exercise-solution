class MovieNotificationJob < ApplicationJob
  queue_as :default

  def perform(movie_ids)
    Movie.where(id: movie_ids).find_each do |movie|
      NotifyMovieSubscribers.call(movie, movie.subscriber_emails)
    end
  end
end
