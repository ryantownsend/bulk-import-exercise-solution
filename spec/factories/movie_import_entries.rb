require "ostruct"
require "securerandom"

FactoryBot.define do
  factory :movie_import_entry, class: OpenStruct do
    transient do
      movie { build(:movie) }
    end

    id { movie.id }
    title { movie.title }
    description { movie.description }
    rating { movie.rating }
    published { movie.published? }
    subscriber_emails { movie.subscriber_emails }
  end
end

