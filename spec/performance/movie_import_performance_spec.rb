require "rails_helper"

RSpec.describe "Importing movies in bulk", type: :request, performance: true do
  # must be divisible by 4
  PERFORMANCE_TEST_ENTRIES = ENV.fetch("PERFORMANCE_TEST_ENTRIES") { 4000 }.to_i

  # we'll prepare our import entries outside of the spec as we want the profiler to time it
  before(:each) do
    @request_body = PerformanceImportPayload.call(PERFORMANCE_TEST_ENTRIES)
    # run garbage collection to clear our memory out
    GC.start
  end

  context "importing thousands of movies (#{PERFORMANCE_TEST_ENTRIES} to be precise)" do
    it "should execute as fast as possible" do
      expect {
        processing_time = measure {
          post "/movie_imports", params: @request_body, headers: {
            "Accept": "application/json",
            "Content-Type": "application/json"
          }

          perform_enqueued_jobs(only: MovieImportJob)
        }

        File.open(Rails.root.join("tmp/performance_profile.txt"), "w") do |contents|
          contents << "Response Time:   #{BigDecimal(response.headers["X-Runtime"]).ceil(3)}s\n"
          contents << "Processing Time: #{processing_time.ceil(3)}s\n"
        end

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)).to have_key("id")

        import = MovieImport.find(JSON.parse(response.body).fetch("id"))
        expect(import.entry_errors.size).to eq(PERFORMANCE_TEST_ENTRIES / 4)
      }.to change(Movie, :count).by(PERFORMANCE_TEST_ENTRIES / 4)
    end
  end
end
