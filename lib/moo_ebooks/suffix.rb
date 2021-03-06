# frozen_string_literal: true

module Ebooks
  # This generator uses data similar to a Markov model, but
  # instead of making a chain by looking up bigrams it uses the
  # positions to randomly replace token array suffixes in one sentence
  # with matching suffixes in another
  # @private
  class SuffixGenerator
    # Build a generator from a corpus of tikified sentences
    # "tikis" are token indexes-- a way of representing words
    # and punctuation as their integer position in a big array
    # of such tokens
    # @param sentences [Array<Array<Integer>>]
    # @return [SuffixGenerator]
    def self.build(sentences)
      SuffixGenerator.new(sentences)
    end

    def initialize(sentences)
      @sentences = sentences.reject(&:empty?)
      @unigrams = {}
      @bigrams = {}

      @sentences.each_with_index do |tikis, i|
        last_tiki = INTERIM
        tikis.each_with_index do |tiki, j|
          @unigrams[last_tiki] ||= []
          @unigrams[last_tiki] << [i, j]

          @bigrams[last_tiki] ||= {}
          @bigrams[last_tiki][tiki] ||= []

          if j == tikis.length - 1 # Mark sentence endings
            @unigrams[tiki] ||= []
            @unigrams[tiki] << [i, INTERIM]
            @bigrams[last_tiki][tiki] << [i, INTERIM]
          else
            @bigrams[last_tiki][tiki] << [i, j + 1]
          end

          last_tiki = tiki
        end
      end
    end

    # Generate a recombined sequence of tikis
    # @param passes [Integer] number of times to recombine
    # @param gram [Symbol] :unigrams or :bigrams (affects how conservative the
    # model is)
    # @return [Array<Integer>]
    def generate(passes = 5, gram = :unigrams)
      index = rand(@sentences.length)
      tikis = @sentences[index]
      used = [index] # Sentences we've already used
      verbatim = [tikis] # Verbatim sentences to avoid reproducing

      passes.times do
        # Map bigram start site => next tiki alternatives
        varsites = make_varsites(tikis, gram, used)

        variant, verbatim, used = make_variant(tikis, varsites, verbatim, used)

        # If we failed to produce a variation from any alternative, there
        # is no use running additional passes-- they'll have the same result.
        break if variant.nil?

        tikis = variant
      end

      tikis
    end

    private

    def make_variant(tikis, varsites, verbatim, used)
      variant = nil
      varsites.to_a.shuffle.each do |site|
        start = site[0]

        site[1].shuffle.each do |alt|
          verbatim << @sentences[alt[0]]
          suffix = @sentences[alt[0]][alt[1]..-1]
          potential = tikis[0..start + 1] + suffix

          # Ensure we're not just rebuilding some segment of another sentence
          next if verbatim.find do |v|
            NLP.subseq?(v, potential) || NLP.subseq?(potential, v)
          end
          used << alt[0]
          variant = potential
          break
        end

        break if variant
      end
      [variant, verbatim, used]
    end

    def make_varsites(tikis, gram, used)
      varsites = {}
      tikis.each_with_index do |tiki, i|
        next_tiki = tikis[i.succ]
        break if next_tiki.nil?

        alternatives = if gram == :unigrams
                         @unigrams[next_tiki]
                       else
                         @bigrams[tiki][next_tiki]
                       end
        # Filter out suffixes from previous sentences
        alternatives.reject! { |a| a[1] == INTERIM || used.include?(a[0]) }
        varsites[i] = alternatives unless alternatives.empty?
      end
      varsites
    end
  end
end
