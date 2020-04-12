# frozen_string_literal: true

require 'test_helper'
require 'sidekiq-crypt/traverser'

class TraverserTest < Sidekiq::Crypt::TestCase
  def test_override_filtered_parameter
    args = [{ a: 123, b: 1 }]
    traverse_with_args(args)
    assert_equal([{ a: 246, b: 1 }], args)
  end

  def test_override_filtered_parameter_inside_an_array
    args = [[1, { a: 123, b: 1 }]]
    traverse_with_args(args)
    assert_equal([[1, { a: 246, b: 1 }]], args)
  end

  def test_override_multiple_filtered_parameter
    args = [{ a: 123, b: 1 }]
    traverse_with_args(args, %w[a b])
    assert_equal([{ a: 246, b: 2 }], args)
  end

  def test_override_multiple_filtered_with_separate_wrapper
    args = [{ a: 123, d: 1 }, [{ a: 1, b: 2 }], { c: 3 }]
    traverse_with_args(args, %w[a b c])
    assert_equal([{ a: 246, d: 1 }, [{ a: 2, b: 4 }], { c: 6 }], args)
  end

  def test_override_params_with_a_regex_filter
    args = [{ secret_key: 123, secret_value: 1 }]
    traverse_with_args(args, [/secret.*/])
    assert_equal([{ secret_key: 246, secret_value: 2 }], args)
  end

  def test_dont_override_hash_if_keys_not_filtered
    args = [{ b: 123, c: 1234 }]
    traverse_with_args(args)
    assert_equal([{ b: 123, c: 1234 }], args)
  end

  def test_dont_process_primitive_fields
    args = [1, nil, 'string']
    traverse_with_args(args)
    assert_equal([1, nil, 'string'], args)
  end

  def test_dont_remove_or_change_primitives_from_arrays
    args = [[1, nil, 'string']]
    traverse_with_args(args)
    assert_equal([[1, nil, 'string']], args)
  end

  private

  def traverse_with_args(args, filters = ['a'], proc = double_proc)
    traverser = Sidekiq::Crypt::Traverser.new(filters)
    traverser.traverse!(args, proc)
  end

  def double_proc
    proc { |_key, param| param * 2 }
  end
end
