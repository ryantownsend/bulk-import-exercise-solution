# frozen_string_literal: true

class Movie < ApplicationRecord
  # attribute definitions
  # note: by supplying a hash, Rails will store as strings, not integers
  enum :publishing_status, {
    unpublished: "unpublished",
    published: "published",
    archived: "archived"
  }, default: "unpublished"

  # validation
  validates :title, :description, presence: true
  validates :rating, numericality: { in: 1..5, allow_nil: false }
  validates :publishing_status, inclusion: { in: publishing_statuses.values, allow_nil: false }

  # callbacks
  after_commit :notify_subscribers

  # updates the publishing status based on a boolean flag - this just adds a
  # little complexity to the import as it's not a simple 1:1 mapping
  # @param [Boolean] value truthy if publishing, falsey if unpublishing
  def published=(value)
    # if given truthy value, mark as published
    if !!value
      self.publishing_status = "published"
    # if we're unpublishing, if it's published, mark as archived
    elsif :published == publishing_status
      self.publishing_status = "archived"
    end
  end

  private

  # notifies each of the (optional) subscribers that this movie has been updated
  # only when attributes were changed
  def notify_subscribers
    if previous_changes.any?
      NotifyMovieSubscribers.call(self, subscriber_emails)
    end
  end
end
