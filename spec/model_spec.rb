# frozen_string_literal: true

require 'spec_helper'
require 'memory_profiler'
require 'tempfile'

def Process.rss
  `ps -o rss= -p #{Process.pid}`.chomp.to_i
end

describe Ebooks::Model do
  describe 'making tweets' do
    before(:all) do
      content = JSON.parse(File.read(path('data/0xabad1dea.json')),
                           symbolize_names: true)
      @model = Ebooks::Model.consume(content)
    end

    it 'generates a tweet' do
      s = @model.update
      expect(s.length).to be <= 140
      puts s
    end

    it 'generates an appropriate response' do
      s = @model.reply('hi')
      expect(s.length).to be <= 140
      expect(s.downcase).to include('hi')
      puts s
    end
  end

  it 'consumes, saves and loads models correctly' do
    model = nil

    report = MemoryUsage.report do
      content = JSON.parse(File.read(path('data/0xabad1dea.json')),
                           symbolize_names: true)
      model = Ebooks::Model.consume(content)
    end
    expect(report.total_memsize).to be < 200_000_000

    file = Tempfile.new('0xabad1dea')
    file.print model.to_json
    file.rewind

    report2 = MemoryUsage.report do
      model = Ebooks::Model.from_json(file.read)
    end
    expect(report2.total_memsize).to be < 4_000_000

    expect(model.tokens[0]).to be_a String
    expect(model.sentences[0][0]).to be_a Integer
    expect(model.mentions[0][0]).to be_a Integer
    expect(model.keywords[0]).to be_a String

    puts "0xabad1dea.model uses #{report2.total_memsize} bytes in memory"
  end

  describe '.consume' do
    it 'interprets lines with @ as mentions' do
      file = Tempfile.new('mentions')
      file.write('{"mentions":["@m1spy hello!"]}')
      file.close

      model = Ebooks::Model.consume(JSON.parse(File.read(file.path),
                                               symbolize_names: true))
      expect(model.sentences.count).to eq 0
      expect(model.mentions.count).to eq 1

      file.unlink
    end

    it 'interprets lines without @ as statements' do
      file = Tempfile.new('statements')
      file.write('{"statuses":["hello!"]}')
      file.close

      model = Ebooks::Model.consume(JSON.parse(File.read(file.path),
                                               symbolize_names: true))
      expect(model.mentions.count).to eq 0
      expect(model.sentences.count).to eq 1

      file.unlink
    end

    it 'handles strange unicode edge-cases' do
      file = Tempfile.new('unicode')
      data = { statuses: ["💞\n💞"] }
      file.write(data.to_json)
      file.close

      model = Ebooks::Model.consume(JSON.parse(File.read(file.path),
                                               symbolize_names: true))
      expect(model.mentions.count).to eq 0
      expect(model.sentences.count).to eq 2

      file.unlink

      p model.update
    end
  end
end
