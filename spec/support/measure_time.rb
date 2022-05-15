module MeasureTime
  def measure(&block)
    start = Time.now
    block.yield
    Time.now - start
  end
end

RSpec.configure do |config|
  config.include MeasureTime
end
