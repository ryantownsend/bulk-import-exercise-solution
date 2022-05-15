require "securerandom"

FactoryBot.define do
  factory :movie do
    id { SecureRandom.uuid }
    title { "A film title" }
    description { "A film description" }
    rating { 2.5 }
    publishing_status { "published" }
    subscriber_emails { ["test@example.com"] }
  end
end

