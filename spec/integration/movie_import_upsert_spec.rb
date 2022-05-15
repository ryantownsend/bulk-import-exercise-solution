require "rails_helper"

RSpec.describe "Importing movies in bulk", type: :request do
  def json_headers
    {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
  end

  context "with movies that exist already" do
    it "should update the movies that have changed" do
      # Arrange
      existing_movie = create(:movie, title: "The old title")

      import_entries = [
        attributes_for(:movie_import_entry, movie: existing_movie, title: "A new title"),
        attributes_for(:movie_import_entry)
      ]

      # Act & Assert
      expect {
        post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers
      }.to change(Movie, :count).by(1).and \
           change { existing_movie.reload.title }.from("The old title").to("A new title")
    end

    it "should notify the subscribers of updated movies only" do
      # Arrange
      existing_movie_a = create(:movie, subscriber_emails: ["test-a@example.com", "test-b@example.com"])
      existing_movie_b = create(:movie, subscriber_emails: ["test-c@example.com", "test-d@example.com"])

      import_entries = [
        attributes_for(:movie_import_entry, movie: existing_movie_a),
        attributes_for(:movie_import_entry, movie: existing_movie_b, title: "A new title")
      ]

      ActiveSupport::CurrentAttributes.reset_all
      ActionMailer::Base.deliveries.clear

      # Act
      post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers

      # Assert
      expect(ActionMailer::Base.deliveries).to_not be_empty
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array(existing_movie_b.subscriber_emails)
    end

    it "should not update the movies publishing status when `published` is not specified" do
      # Arrange
      existing_movie_a = create(:movie, publishing_status: "unpublished", title: "A1")
      existing_movie_b = create(:movie, publishing_status: "published", title: "B1")

      import_entries = [
        attributes_for(:movie_import_entry, movie: existing_movie_a, title: "A2").slice(:id, :title),
        attributes_for(:movie_import_entry, movie: existing_movie_b, title: "B2").slice(:id, :title)
      ]

      # Act
      post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers

      existing_movie_a.reload
      existing_movie_b.reload

      # Assert
      aggregate_failures do
        expect(existing_movie_a.title).to eq("A2")
        expect(existing_movie_a).to be_unpublished
        expect(existing_movie_b.title).to eq("B2")
        expect(existing_movie_b).to be_published
      end
    end
  end
end
