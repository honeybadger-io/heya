require "test_helper"

class Heya::Test < ActiveSupport::TestCase
  class User
    def foo
      "foo"
    end

    def bar
      "bar"
    end

    def true?
      true
    end

    def false?
      false
    end
  end

  test "#in_segments? returns true when all segments match user" do
    assert Heya.in_segments?(User.new, ->(u) { u.foo == "foo" }, ->(u) { u.bar == "bar" })
  end

  test "#in_segments? returns false when one or more segments don't match user" do
    refute Heya.in_segments?(User.new, ->(u) { u.foo == "foo" }, ->(u) { u.bar == "baz" })
  end

  test "#in_segments? matches symbol segments" do
    assert Heya.in_segments?(User.new, :true?)
    refute Heya.in_segments?(User.new, :false?)
  end
end
