class MovieNotificationJob < ApplicationJob
  queue_as :default

  def perform(movie_id)
    movie = Movie.find(movie_id)
    NotifyMovieSubscribers.call(movie, movie.subscriber_emails)
  end
end
