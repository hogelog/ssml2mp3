$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "ssml2mp3"

require "pry"

def fixture_path(path)
  File.join(File.dirname(__FILE__), "fixtures", path)
end
