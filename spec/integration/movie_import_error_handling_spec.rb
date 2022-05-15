require "rails_helper"

RSpec.describe "Importing movies in bulk", type: :request do
  def json_headers
    {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
  end

  context "with erroneous import entries" do
    it "should record the errors against the import" do
      # Arrange
      import_entries = [
        attributes_for(:movie_import_entry, title: nil),
        attributes_for(:movie_import_entry, description: nil),
        attributes_for(:movie_import_entry, rating: 5.5)
      ]

      # Act & Assert
      expect {
        post "/movie_imports", params: JSON.dump(import_entries), headers: json_headers
      }.to_not change(Movie, :count)

      expect(response).to have_http_status(:created)
      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body)).to have_key("id")

      import = MovieImport.find(JSON.parse(response.body).fetch("id"))
      expect(import.entry_errors.size).to eq(3)
      expect(import.entry_errors.first).to include("entry #1")
      expect(import.entry_errors.second).to include("entry #2")
      expect(import.entry_errors.third).to include("entry #3")
    end
  end

  context "with invalid JSON" do
    it "should render an error" do
      # Act
      post "/movie_imports", params: "[}", headers: json_headers

      # Assert
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end
end
