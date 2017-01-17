require "ssml2mp3/version"
require "ssml2mp3/builder"

require "logger"

module Ssml2mp3
  def self.builder
    @builder ||= ::Ssml2mp3::Builder.new(logger: Logger.new(STDOUT))
  end

  def self.synthesize(*args)
    builder.synthesize(*args)
  end

  def self.synthesize_file(*args)
    builder.synthesize_file(*args)
  end
end
