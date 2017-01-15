require "spec_helper"

describe Ssml2mp3::Builder do
  let(:builder) { Ssml2mp3::Builder.new }
  let(:ssml) { File.read(fixture_path("hashire_merosu.ssml")) }

  describe ".split_ssml" do
    subject { builder.split_ssml }

    it do
      is_expected.not_to eq(0)
      expect(subject[0]).to include("太宰治")
    end
  end
end
