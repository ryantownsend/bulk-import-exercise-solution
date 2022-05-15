require "factory_bot_rails"

module PerformanceImportPayload
  extend FactoryBot::Syntax::Methods

  def self.call(total_entry_count)
    # in this test we're going to aim for:
    #   one quarter new movies
    #   one quarter updated movies
    #   one quarter existing but not updated movies
    #   one quarter erroneous entries

    existing_movies = create_list(:movie, total_entry_count / 2)

    # updated movies
    movie_import_entries = 1.upto(total_entry_count / 2).map { |i|
      movie = existing_movies[i - 1]

      if i.odd?
        attributes_for(:movie_import_entry, movie: movie)
      else
        attributes_for(:movie_import_entry,
          movie: movie,
          title: "Updated #{movie.title}",
          published: [true, false].sample,
          subscriber_emails: [
            ["test-a@example.com", "test-b@example.com"],
            ["test-c@example.com"],
            []
          ].sample
        )
      end
    }

    # new movies
    1.upto(total_entry_count / 4).each_with_object(movie_import_entries) { |_, entries|
      entries << attributes_for(:movie_import_entry)
    }

    # failing entries
    1.upto(total_entry_count / 4).each_with_object(movie_import_entries) { |_, entries|
      entries << attributes_for(:movie_import_entry, rating: 5.5)
    }

    # randomise the order and dump out to JSON
    JSON.dump(movie_import_entries.shuffle)
  end
end
