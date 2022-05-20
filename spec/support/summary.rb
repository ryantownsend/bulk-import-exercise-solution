RSpec.configure do |config|
  config.after(:suite, performance: true) do
    file_location = ENV.fetch("GITHUB_STEP_SUMMARY", Rails.root.join("tmp/summary.md"))

    File.open(file_location, "w") do |contents|

      contents << "## API Performance\n\n"
      if File.exist?(perf_file = Rails.root.join("tmp/performance_profile.md"))
        contents << File.read(perf_file)
      else
        contents << "⚠️ tmp/performance_profile.md not found\n"
      end
      contents << "\n"

      contents << "## API Memory Consumption\n\n"
      if File.exist?(mem_file = Rails.root.join("tmp/memory_profile.txt"))
        if File.readlines(mem_file).first =~ /^total\sallocated\:\s(.+)\s\((\d+)\sobjects\)/i
          contents << "| Memory Allocated  | #{$1} |\n"
          contents << "| Objects Allocated | #{$2} |\n"
        else
          contents << "⚠️ Unable to parse tmp/memory_profile.txt\n"
        end
      else
        contents << "⚠️ tmp/memory_profile.txt not found\n"
      end

    end
  end
end
