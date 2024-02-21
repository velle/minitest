# encoding: UTF-8

require "minitest/autorun"

if defined? Encoding then
  e = Encoding.default_external
  if e != Encoding::UTF_8 then
    warn ""
    warn ""
    warn "NOTE: External encoding #{e} is not UTF-8. Tests WILL fail."
    warn "      Run tests with `RUBYOPT=-Eutf-8 rake` to avoid errors."
    warn ""
    warn ""
  end
end

class TestMinitestAssertionsJson < Minitest::Test
  # do not call parallelize_me! - teardown accesses @tc._assertions
  # which is not threadsafe. Nearly every method in here is an
  # assertion test so it isn't worth splitting it out further.

  class DummyTest
    include Minitest::Assertions

    attr_accessor :assertions, :failure

    def initialize
      self.assertions = 0
      self.failure = nil
    end
  end

  def setup
    super

    Minitest::Test.reset

    @tc = DummyTest.new
    @zomg = "zomg ponies!" # TODO: const
    @assertion_count = 1
  end

  def teardown
    assert_equal(@assertion_count, @tc.assertions,
                 "expected #{@assertion_count} assertions to be fired during the test, not #{@tc.assertions}")
  end

  def test_assert
    @assertion_count = 2
    @tc.assert_equal true, @tc.assert(true), "returns true on success"
  end

end
