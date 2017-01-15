require "spec_helper"

describe Ssml2mp3 do
  descirbe ".synthesize" do
    let(:ssml) { File.read(fixture_path("hashire_merosu.ssml")) }

    it do
      File.open("tmp/merosu.mp3", "wb") do |output|
        Ssml2mp3.synthesize(ssml, output)
      end
    end
  end
end
