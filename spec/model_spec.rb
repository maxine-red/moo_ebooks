# frozen_string_literal: true

require 'spec_helper'
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
    end

    it 'generates an appropriate response' do
      s = @model.reply('hi')
      expect(s.length).to be <= 140
      expect(s.downcase).to include('hi')
    end
  end

  it 'consumes, saves and loads models correctly' do
    content = JSON.parse(File.read(path('data/0xabad1dea.json')),
                         symbolize_names: true)
    model = Ebooks::Model.consume(content)
    file = Tempfile.new('0xabad1dea')
    file.print model.to_json
    file.rewind

    model = Ebooks::Model.from_json(file.read)

    expect(model.tokens[0]).to be_a String
    expect(model.sentences[0][0]).to be_a Integer
    expect(model.mentions[0][0]).to be_a Integer
    expect(model.keywords[0]).to be_a String
  end

  describe '.consume' do
    it 'interprets lines with @ as mentions' do
      model = Ebooks::Model.consume(mentions: ['@m1spy hello!'])
      expect(model.sentences.count).to eq 0
      expect(model.mentions.count).to eq 1
    end

    it 'interprets lines without @ as statements' do
      model = Ebooks::Model.consume(statuses: ['hello!'])
      expect(model.mentions.count).to eq 0
      expect(model.sentences.count).to eq 1
    end

    it 'handles strange unicode edge-cases' do
      model = Ebooks::Model.consume(statuses: ["💞\n💞"])
      expect(model.mentions.count).to eq 0
      expect(model.sentences.count).to eq 2
      model.update
    end
  end
end
