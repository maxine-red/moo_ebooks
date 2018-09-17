# frozen_string_literal: true

require 'json'
require 'set'
require 'digest/md5'

module Ebooks
  # Main class for Model management. Models are required for text generation.
  #
  # @notice Only JSON format is supported.
  # @notice For corpus files. These are assumed to have a `statuses` key and a
  # `mentions` key, which hold the different statuses in them.
  #
  # @notice Make sure NOT to include reblogs (retweets) into corpus data. Those
  # will negatively impact text creation
  class Model
    # @return [Array<String>]
    # An array of unique tokens. This is the main source of actual strings
    # in the model. Manipulation of a token is done using its index
    # in this array, which we call a "tiki"
    attr_accessor :tokens

    # @return [Array<Array<Integer>>]
    # Sentences represented by arrays of tikis
    attr_accessor :sentences

    # @return [Array<Array<Integer>>]
    # Sentences derived from Twitter mentions
    attr_accessor :mentions

    # @return [Array<String>]
    # The top 200 most important keywords, in descending order
    attr_accessor :keywords
    def initialize
      @tokens = []
      @sentences = []
      @mentions = []
      @keywords = []

      # Reverse lookup tiki by token, for faster generation
      @tikis = {}
    end

    # Load a saved model
    # @param data [Hash]
    # @return [Ebooks::Model]
    def self.from_hash(data)
      model = Model.new
      model.tokens = data[:tokens]
      model.sentences = data[:sentences]
      model.mentions = data[:mentions]
      model.keywords = data[:keywords]
      model
    end

    # Load a saved model
    # @param data [String]
    # @reutrn [Ebooks::Model]
    def self.from_json(data)
      from_hash(JSON.parse(data, symbolize_names: true))
    end

    # Turn this model into its JSON representation.
    def to_json
      to_hash.to_json
    end

    # Turn this model into its Hash representation
    def to_hash
      { tokens: @tokens, sentences: @sentences, mentions: @mentions,
        keywords: @keywords }
    end

    # Consume a corpus into this model
    # @param content [Hash]
    def consume(content)
      model = Ebooks::Model.new
      model.consume!(content)
      model
    end

    # Consume a corpus into this model
    # @param content [Hash]
    def consume!(content)
      unless content.key?(:statuses) || content.key?(:mentions)
        raise ArgumentError, 'Malformed hash object. At least :statuses and/or'\
                             ' :mentions must be present as a key'
      end
      consume_statuses(content[:statuses]) unless content[:statuses].nil?
      consume_mentions(content[:mentions]) unless content[:mentions].nil?
      nil
    end

    # Generate some text
    # @param limit [Integer] available characters
    # @param generator [SuffixGenerator, nil]
    # @param retry_limit [Integer] how many times to retry on invalid status
    # @return [String]
    def update(limit = 140, generator = nil, retry_limit = 10)
      tikis = gather_tikis(limit, generator, retry_limit)

      status = NLP.reconstruct(tikis, @tokens)

      fix status
    end

    # Generates a response by looking for related sentences
    # in the corpus and building a smaller generator from these
    # @param input [String]
    # @param limit [Integer] characters available for response
    # @param sentences [Array<Array<Integer>>]
    # @return [String]
    def reply(input, limit = 140, sentences = @mentions)
      # Prefer mentions
      relevant, slightly_relevant = find_relevant(sentences, input)

      if relevant.length >= 3
        generator = SuffixGenerator.build(relevant)
        update(limit, generator)
      elsif slightly_relevant.length >= 5
        generator = SuffixGenerator.build(slightly_relevant)
        update(limit, generator)
      else
        update(limit)
      end
    end

    private

    def gather_tikis(limit, generator, retry_limit)
      responding = !generator.nil?
      generator ||= SuffixGenerator.build(@sentences)

      @retries = 0

      tikis = make_bigram_tikis(limit, generator, retry_limit, responding)

      if verbatim?(tikis) && tikis.length > 3
        # We made a verbatim status by accident
        tikis = make_unigram_tikis(limit, generator, retry_limit)
      end
      @retries = nil
      tikis
    end

    def make_unigram_tikis(limit, generator, retry_limit)
      while (tikis = generator.generate(3, :unigrams))
        break if valid_status?(tikis, limit) && !verbatim?(tikis)

        @retries += 1
        break if retry_limit_reached?(retry_limit)
      end
      tikis
    end

    def make_bigram_tikis(limit, generator, retry_limit, responding)
      while (tikis = generator.generate(3, :bigrams))
        break if (tikis.length > 3 || responding) && valid_status?(tikis, limit)

        @retries += 1
        break if retry_limit_reached?(retry_limit)
      end
      tikis
    end

    def retry_limit_reached?(retry_limit)
      @retries >= retry_limit
    end

    # Reverse lookup a token index from a token
    # @param token [String]
    # @return [Integer]
    def tikify(token)
      if @tikis.key?(token)
        @tikis[token]
      else
        @tokens << token
        @tikis[token] = @tokens.length - 1
      end
    end

    # Convert a body of text into arrays of tikis
    # @param text [String]
    # @return [Array<Array<Integer>>]
    def mass_tikify(text)
      sentences = NLP.sentences(text)

      sentences.map do |s|
        tokens = NLP.tokenize(s).reject do |t|
          # Don't include usernames/urls as tokens
          t.include?('@') || t.include?('http')
        end

        tokens.map { |t| tikify(t) }
      end
    end

    # Test if a sentence has been copied verbatim from original
    # @param tikis [Array<Integer>]
    # @return [Boolean]
    def verbatim?(tikis)
      @sentences.include?(tikis) || @mentions.include?(tikis)
    end

    # Check if an array of tikis comprises a valid status
    # @param tikis [Array<Integer>]
    # @param limit Integer how many chars we have left
    def valid_status?(tikis, limit)
      status = NLP.reconstruct(tikis, @tokens)
      status.length <= limit && !NLP.unmatched_enclosers?(status)
    end

    # Consume a sequence of statuses (excluding mentions)
    # @param statuses [Array<String>]
    def consume_statuses(statuses)
      statuses.map! do |status|
        NLP.normalize(status)
      end

      text = statuses.join("\n").encode('UTF-8', invalid: :replace)
      @sentences = mass_tikify(text)
      @keywords = NLP.keywords(text).top(200).map(&:to_s)

      nil
    end

    # Consume a sequence of mentions
    # @param mentions [Array<String>]
    def consume_mentions(mentions)
      mentions.map! do |mention|
        NLP.normalize(mention)
      end

      mention_text = mentions.join("\n").encode('UTF-8', invalid: :replace)
      @mentions = mass_tikify(mention_text)

      nil
    end

    # Correct encoding issues in generated text
    # @param text [String]
    # @return [String]
    def fix(text)
      NLP.htmlentities.decode text
    end

    # Finds relevant and slightly relevant tokenized sentences to input
    # comparing non-stopword token overlaps
    # @param sentences [Array<Array<Integer>>]
    # @param input [String]
    # @return [Array<Array<Array<Integer>>, Array<Array<Integer>>>]
    def find_relevant(sentences, input)
      relevant = []
      slightly_relevant = []

      tokenized = NLP.tokenize(input).map(&:downcase)

      sentences.each do |sent|
        tokenized.each do |token|
          if sent.map { |tiki| @tokens[tiki].downcase }.include?(token)
            relevant << sent unless NLP.stopword?(token)
            slightly_relevant << sent
          end
        end
      end

      [relevant, slightly_relevant]
    end
  end
end
