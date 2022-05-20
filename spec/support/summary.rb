module RSpecSummary
  def self.summary_output_file
    ENV.fetch("GITHUB_STEP_SUMMARY", Rails.root.join("tmp/summary.md"))
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    unless ENV["GITHUB_STEP_SUMMARY"]
      File.delete(RSpecSummary.summary_output_file) if File.exist?(RSpecSummary.summary_output_file)
    end
  end
end
