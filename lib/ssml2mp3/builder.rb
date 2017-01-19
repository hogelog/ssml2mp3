require "aws-sdk-polly"
require "logger"
require "nokogiri"
require "expeditor"
require "concurrent"
require "tmpdir"

module Ssml2mp3
  class Builder
    attr_reader :options, :sample_rate, :client, :logger, :expeditor_service

    POLLY_TEXT_LENGTH_LIMIT = 1000

    def initialize(options={})
      @options = options.dup
      @logger = @options.delete(:logger) || Logger.new(STDOUT)
      @sample_rate = @options.delete(:sample_rate) || "16000"
      @max_threads = @options.delete(:max_threads) || 10
      @options[:region] ||= "us-west-2"

      @client = Aws::Polly::Client.new(@options)
      @expeditor_service = Expeditor::Service.new(
        executor: Concurrent::ThreadPoolExecutor.new(
          min_threads: 0,
          max_threads: @max_threads,
        )
      )
    end

    def synthesize_file(ssml_path, mp3_path)
      basename = File.basename(mp3_path, ".mp3")
      ssml = File.read(ssml_path)
      File.open(mp3_path, "wb") do |output|
        synthesize(ssml, basename, output)
      end
      logger.info("Generated: #{mp3_path}") if logger
    end

    def synthesize(ssml, basename, output)
      ssmls = split_ssml(ssml)

      tmp_files = []
      commands = []

      Dir.mktmpdir("foo") do |tmpdir|
        ssmls.each_with_index do |ssml, i|
          tmp_ssml_path = File.join(tmpdir, "#{basename}-#{i}.ssml")
          File.write(tmp_ssml_path, ssml)
          tmp_path = File.join(tmpdir, "#{basename}-#{i}.mp3")
          command = Expeditor::Command.new(service: expeditor_service) do
            logger.info("#{tmp_path}...") if logger
            begin
              client.synthesize_speech(
                response_target: tmp_path,
                output_format: "mp3",
                sample_rate: sample_rate,
                text: ssml,
                text_type: "ssml",
                voice_id: "Mizuki",
              )
            rescue => e
              logger.error("#{e.message}\n#{ssml}")
              logger.error("#{e.message}: #{tmp_ssml_path}\n#{ssml}")
              raise e
            end
          end
          command.start
          commands << command
          tmp_files << tmp_path
        end
        commands.each{|command| command.get }

        tmp_files.each do |tmp_path|
          File.open(tmp_path, "rb") do |tmp_file|
            IO.copy_stream(tmp_file, output)
          end
        end
        output.flush
      end
    end

    def split_ssml(ssml)
      doc = Nokogiri::XML.parse(tweak_ssml(ssml))
      elements = doc.root.children

      header = (%r((.+<speak[^>]+>))m === ssml && $1)

      results = []
      buffer = ""

      while elements.size > 0 do
        element = elements.shift

        case element
          when Nokogiri::XML::Text
            text = html_encode(element.text)
          when String
            text = html_encode(element)
          else
            buffer += element.to_s
            next
        end

        if text.size > POLLY_TEXT_LENGTH_LIMIT
          split_texts = text.chars.each_slice(POLLY_TEXT_LENGTH_LIMIT).map(&:join)
          elements = split_texts + elements
          next
        end

        if text_size(buffer + text) > POLLY_TEXT_LENGTH_LIMIT
          results << buffer
          buffer = ""
        end

        buffer += text
      end

      results << buffer if buffer.size > 0

      results.map do |body_ssml|
        header + body_ssml + "</speak>"
      end
    end

    def text_size(text)
      text.gsub("</?[^>]+>", '').size
    end

    def tweak_ssml(ssml)
      ssml.
        gsub("\n", "").
        gsub("<p>", "").
        gsub("</p>", '<break strength="strong"/>').
        gsub(/([」】）』])/, '\1<break strength="strong"/>')
    end

    def html_encode(text)
      text.gsub(/</, "&lt;").gsub(/>/, "&gt;")
    end
  end
end
