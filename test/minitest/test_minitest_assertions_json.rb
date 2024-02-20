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

SomeError = Class.new Exception

unless defined? MyModule then
  module MyModule; end
  class AnError < StandardError; include MyModule; end
end

class TestMinitestAssertionsJson < Minitest::Test
  # do not call parallelize_me! - teardown accesses @tc._assertions
  # which is not threadsafe. Nearly every method in here is an
  # assertion test so it isn't worth splitting it out further.

  RUBY18 = !defined? Encoding

  # not included in JRuby
  RE_LEVELS = /\(\d+ levels\) /

  class DummyTest
    include Minitest::Assertions
    # include Minitest::Reportable # TODO: why do I really need this?

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

  def assert_deprecated name
    dep = /DEPRECATED: #{name}. From #{__FILE__}:\d+(?::.*)?/
    dep = "" if $-w.nil?

    assert_output nil, dep do
      yield
    end
  end

  def assert_triggered expected, klass = Minitest::Assertion
    e = assert_raises klass do
      yield
    end

    msg = e.message.sub(/(---Backtrace---).*/m, '\1')
    msg.gsub!(/\(oid=[-0-9]+\)/, "(oid=N)")
    msg.gsub!(/(\d\.\d{6})\d+/, '\1xxx') # normalize: ruby version, impl, platform

    assert_msg = Regexp === expected ? :assert_match : :assert_equal
    self.send assert_msg, expected, msg
  end

  def assert_unexpected expected
    expected = Regexp.new expected if String === expected

    assert_triggered expected, Minitest::UnexpectedError do
      yield
    end
  end

  def clean s
    s.gsub(/^ {6,10}/, "")
  end

  def non_verbose
    orig_verbose = $VERBOSE
    $VERBOSE = false

    yield
  ensure
    $VERBOSE = orig_verbose
  end

  def test_assert
    @assertion_count = 2

    @tc.assert_equal true, @tc.assert(true), "returns true on success"
  end

  def test_assert__triggered
    assert_triggered "Expected false to be truthy." do
      @tc.assert false
    end
  end

  def test_assert__triggered_message
    assert_triggered @zomg do
      @tc.assert false, @zomg
    end
  end

end
