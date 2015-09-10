$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'eb/dockerrun/deploy'
require 'fakefs/safe'
RSpec.configure do |config|
  config.before do
    FakeFS.activate!
  end

  config.after do
    FakeFS.deactivate!
  end
end
