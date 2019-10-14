require 'uri'

module Sidekiq
  module Crypt
    class Traverser
      def initialize(configuration)
        @filters = configuration.filters
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
            if filter_match?(key)
              clean_hash[key] = proc.call(value)
            else
              clean_hash[key] = traverse(value, proc)
            end
          end

          clean_hash
        when Array
          object.map { |element| traverse(element, proc) }
        else object
        end
      end

      def filter_match?(key)
        key = key.to_s

        @filters.any? do |filter|
          case filter
          when Regexp then key.match(filter)
          else key.include?(filter.to_s)
          end
        end
      end
    end
  end
end
