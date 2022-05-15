class MovieNotification < ApplicationRecord
  # associations
  belongs_to :movie

  # validation
  validates :email, presence: true
end
