require "rails_helper"

RSpec.describe "Importing movies in bulk", type: :request do
  def json_headers
    {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
  end

  context "with entirely new movies" do
    it "should create new movies in the database" do
      # Arrange
      import_entries = [
        attributes_for(:movie_import_entry),
        attributes_for(:movie_import_entry),
        attributes_for(:movie_import_entry)
      ]

      # Act & Assert
      expect {
        post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)).to have_key("id")
      }.to change(MovieImport, :count).by(1).and \
           change(Movie, :count).by(3)
    end

    it "should notify their subscribers" do
      # Arrange
      import_entries = [
        entry_a = attributes_for(:movie_import_entry, subscriber_emails: ["test-a@example.com"]),
        entry_b = attributes_for(:movie_import_entry, subscriber_emails: ["test-a@example.com"]),
        entry_c = attributes_for(:movie_import_entry, subscriber_emails: ["test-b@example.com"])
      ]

      # Act
      post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers

      # Assert
      expect(ActionMailer::Base.deliveries).to_not be_empty
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to match_array(
        entry_a[:subscriber_emails] +
        entry_b[:subscriber_emails] +
        entry_c[:subscriber_emails]
      )
    end

    it "should default new movies to unpublished" do
      # Arrange
      import_entries = [attributes_for(:movie_import_entry, published: nil).compact]

      # Act & Assert
      expect {
        post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers
      }.to change(Movie.unpublished, :count).by(1)
    end

    it "should record the start and finish time" do
      # Arrange
      import_entries = [attributes_for(:movie_import_entry)]

      # Act
      post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers

      # Assert
      expect(response).to have_http_status(:created)
      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body)).to have_key("id")

      import = MovieImport.find(JSON.parse(response.body).fetch("id"))
      expect(import.started_at).to be_present
      expect(import.finished_at).to be_present
      expect(import.finished_at).to be >= import.started_at
    end
  end
end
