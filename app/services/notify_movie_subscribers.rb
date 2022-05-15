module NotifyMovieSubscribers
  # notifies the given list of emails about the given movie being created/updated
  # @param [Movie] movie
  # @param [Array<String>] emails
  def self.call(movie, emails)
    Array(emails).each do |email|
      MovieMailer.with(email: email, movie: movie).update_email.deliver_now
      MovieNotification.create!(email: email, movie: movie)
    end
  end
end
