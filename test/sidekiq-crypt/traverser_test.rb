# frozen_string_literal: true

require "test_helper"
require 'sidekiq-crypt/traverser'

class TraverserTest < Sidekiq::Crypt::TestCase
  FILTERS = Struct.new(:filters)

  def test_override_filtered_parameter
    traverse_with_args([{ a: 123, b: 1 }]) do |args|
      assert_equal([{ a: 246, b: 1 }], args)
    end
  end

  def test_override_filtered_parameter_inside_an_array
    traverse_with_args([[1, { a: 123, b: 1 }]]) do |args|
      assert_equal([[1, { a: 246, b: 1 }]], args)
    end
  end

  def test_override_multiple_filtered_parameter
    traverse_with_args([{ a: 123, b: 1 }], ['a', 'b']) do |args|
      assert_equal([{ a: 246, b: 2 }], args)
    end
  end

  def test_override_multiple_filtered_with_separate_wrapper
    params = [{ a: 123, d: 1 }, [{ a: 1, b: 2 }], { c: 3 }]
    traverse_with_args(params, ['a', 'b', 'c']) do |args|
      assert_equal([{ a: 246, d: 1 }, [{ a: 2, b: 4 }], { c: 6 }], args)
    end
  end

  def test_override_params_with_a_regex_filter
    traverse_with_args([{ secret_key: 123, secret_value: 1 }], [/secret.*/]) do |args|
      assert_equal([{ secret_key: 246, secret_value: 2 }], args)
    end
  end

  def test_dont_override_hash_if_keys_not_filtered
    traverse_with_args([{ b: 123, c: 1234 }]) do |args|
      assert_equal([{ b: 123, c: 1234 }], args)
    end
  end

  def test_dont_process_primitive_fields
    traverse_with_args([1, nil, 'string']) do |args|
      assert_equal([1, nil, 'string'], args)
    end
  end

  def test_dont_remove_or_change_primitives_from_arrays
    traverse_with_args([[1, nil, 'string']]) do |args|
      assert_equal([[1, nil, 'string']], args)
    end
  end

  private

  def traverse_with_args(args, filters = ['a'])
    traverser = Sidekiq::Crypt::Traverser.new(FILTERS.new(filters))
    proc = Proc.new { |param| param * 2 }

    traverser.traverse!(args, proc)

    yield args
  end
end
