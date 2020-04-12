# frozen_string_literal: true

require 'uri'

module Sidekiq
  module Crypt
    class Traverser
      def initialize(filters)
        @filters = filters
      end

      def traverse!(args, proc)
        args.each_with_index do |arg, index|
          next unless arg.is_a?(Hash) || arg.is_a?(Array)

          # override the params
          args[index] = traverse(arg, proc)
        end
      end

      private

      def traverse(object, proc)
        # sidekiq arguments must be serialized as JSON.
        # Therefore, object could be hash, array or primitives like string/number
        # Also, recursive hashes or arrays is not possible.
        case object
        when Hash
          clean_hash = {}

          object.each do |key, value|
            clean_hash[key] = filter_match?(key) ? proc.call(key, value) : traverse(value, proc)
          end

          clean_hash
        when Array then object.map { |element| traverse(element, proc) }
        else object
        end
      end

      def filter_match?(key)
        @filters.any? do |filter|
          case filter
          when Regexp then key.to_s.match(filter)
          else key.to_s == filter.to_s
          end
        end
      end
    end
  end
end
