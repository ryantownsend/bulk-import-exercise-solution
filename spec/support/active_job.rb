require "active_job"

RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  config.around(:each) do |example|
    # if we're running a performance spec
    if !!example.metadata[:performance]
      # let it enqueue jobs in it's own way
      example.run
    # if we're running integration specs
    else
      # perform all jobs synchronously to validate behaviour
      perform_enqueued_jobs { example.run }
    end
  end
end
