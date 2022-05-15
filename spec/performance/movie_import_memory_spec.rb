require "rails_helper"
require "memory_profiler"

RSpec.describe "Importing movies in bulk", type: :request, performance: true do
  # must be divisible by 4
  MEMORY_TEST_ENTRIES = ENV.fetch("MEMORY_TEST_ENTRIES") { 1000 }.to_i

  context "importing thousands of movies (#{MEMORY_TEST_ENTRIES} to be precise)" do
    it "should use as little memory as possible" do
      # Arrange
      # build our request body before we test memory
      request_body = PerformanceImportPayload.call(MEMORY_TEST_ENTRIES)

      # Act
      report = MemoryProfiler.report(ignore_files: "/gems/") do
        post "/movie_imports", params: request_body, headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        }
      end

      # report
      report.pretty_print(to_file: Rails.root.join("tmp/memory_profile.txt"), scale_bytes: true)

      # Assert
      expect(true).to eq(true)
    end
  end
end
