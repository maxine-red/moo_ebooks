# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

# TODO: Define API here, get 100% test coverage and make rubocop not throw more
# offenses

describe Ebooks::Model, '.new' do
  it 'returns an Ebooks::Model instance' do
    expect(Ebooks::Model.new).to be_a Ebooks::Model
  end
end

model = Ebooks::Model.new

describe Ebooks::Model, '#consume' do
  context 'a properly formed hash is given' do
    it 'returns a a different Ebooks::Model instance' do
      content = JSON.parse(File.read(path('data/0xabad1dea.json')),
                           symbolize_names: true)
      m2 = model.consume(content)
      expect(m2).to be_a Ebooks::Model
      expect(m2).not_to be model
      model.consume!(content)
    end
  end
  context 'a malformed hash is given' do
    it 'raises an ArgumentError' do
      expect { model.consume({}) }.to raise_error ArgumentError
    end
  end
end

# consume also tests comsume!

describe Ebooks::Model, '#tokens' do
  it 'returns an array of string' do
    expect(model.tokens).to be_an Array
    expect(model.tokens.first).to be_a String
  end
end

describe Ebooks::Model, '#sentences' do
  it 'returns an array of array of numbers' do
    expect(model.sentences).to be_an Array
    expect(model.sentences.first).to be_an Array
    expect(model.sentences.first.first).to be_an Integer
  end
end

describe Ebooks::Model, '#mentions' do
  it 'returns an array of array of numbers' do
    expect(model.mentions).to be_an Array
    expect(model.mentions.first).to be_an Array
    expect(model.mentions.first.first).to be_an Integer
  end
end

describe Ebooks::Model, '#keywords' do
  it 'returns an array of string' do
    expect(model.keywords).to be_an Array
    expect(model.keywords.first).to be_a String
  end
end

describe Ebooks::Model, '#to_hash' do
  it 'returns a hash representation of this model' do
    expect(model.to_hash).to be_a Hash
  end
end

describe Ebooks::Model, '#to_json' do
  it 'returns a JSON string' do
    expect(model.to_json).to be_a String
    expect(JSON.parse(model.to_json).keys.first).to be_a String
  end
end

describe Ebooks::Model, '#create_status' do
  it 'returns a status, that can be posted onto social media' do
    expect(model.update).to be_a String
    expect(model.update.length).to be <= 140
  end
end

describe Ebooks::Model, '#create_reply' do
  it 'returns an appropriate reply, that can be posted onto social media' do
    expect(model.reply('hi')).to be_a String
    expect(model.reply('some ISP in Russia')).to be_a String
    expect(model.reply('abx')).to be_a String
    expect(model.reply('hi').length).to be <= 140
    expect(model.reply('hi').downcase).to match('hi')
  end
end

describe Ebooks::Model, '.from_hash' do
  it 'reads a hash representation of a model and returns a model' do
    expect(Ebooks::Model.from_hash(model.to_hash)).to be_a Ebooks::Model
  end
end

describe Ebooks::Model, '.from_json' do
  it 'reads a JSON representation of a model and returns a model' do
    expect(Ebooks::Model.from_json(model.to_json)).to be_a Ebooks::Model
  end
end
