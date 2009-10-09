require 'test/unit'
require 'rubygems'
require 'shoulda'
require File.join(File.dirname(__FILE__), "..", "convert_srt")

class ConverterTest < Test::Unit::TestCase
  context Converter::HMS do
    setup do
      ENV['hour_start'] = '1'
      ENV['min_start'] = '40'
      ENV['sec_start'] = '50'
      ENV['mills_start'] = '700'
      ENV['count_start'] = '15'
      ENV['strategy'] = 'Converter::HMS'
      @processor = processor
    end

    should "convert values adds offsets up when no overflow" do
      count_processed, start_processed, end_processed = @processor.convert_values 1, "01:01:01,100", "02:02:02:200"
      assert_equal(16, count_processed)
      assert_equal("02:41:51,800", start_processed)
      assert_equal("03:42:52,900", end_processed)
    end

    should "convert values adds offsets up with overflow" do
      processed = @processor.convert_time "01:20:12,400"
      assert_equal("03:01:03,100", processed)
    end

    should "convert should generate replacement in correct format" do
      processed = @processor.convert(10, "00:00:00,000", "00:00:00,000")
      assert_equal("25
01:40:50,700 --> 01:40:50,700", processed)
    end

    should "process should return content replacement" do
      contents = @processor.process <<-IN
1
01:01:01,001 --> 02:02:02,002
Foo bar

2
03:03:03,003 --> 04:04:04,004
Bar baz

3
05:05:05,005 --> 06:06:06,006
Baz quux
IN
      expected = <<-OUT
16
02:41:51,701 --> 03:42:52,702
Foo bar

17
04:43:53,703 --> 05:44:54,704
Bar baz

18
06:45:55,705 --> 07:46:56,706
Baz quux
OUT
      assert_equal(expected, contents)
    end

    context "with incomplete env setup" do
      teardown do
        begin
          @processor.check_sanity
          fail "sanity check should have failed."
        rescue
          assert_equal("provide hour_start=HH min_start=MM sec_start=SS mills_start=mmm count_start=C for this strategy", $!.message)
        end
      end

      should "fail for missing hour_start value" do
        ENV.delete('hour_start')
      end

      should "fail for missing min_start value" do
        ENV.delete('min_start')
      end

      should "fail for missing sec_start value" do
        ENV.delete('sec_start')
      end

      should "fail for missing mills_start value" do
        ENV.delete('mills_start')
      end

      should "fail for missing count_start value" do
        ENV.delete('count_start')
      end
    end
  end

  context Converter::Number do
    setup do
      ENV['offset'] = '12'
      ENV['strategy'] = 'Converter::Number'
      @processor = processor
    end

    should "fail for missing offset" do
      begin
        ENV.delete('offset')
        @processor.check_sanity
        fail "sanity check should have failed"
      rescue
        assert_equal("provide offset=X(number) for this strategy", $!.message)
      end
    end

    should "convert start number and end number with correct offset" do
      assert_equal("{27}{37}", @processor.convert(15, 25))
    end

    should "process contents well" do
      contents = @processor.process <<-IN
{1}{2}Foo|bar

{3}{4}Bar baz

{5}{6}Baz|quux
IN
      expected = <<-OUT
{13}{14}Foo|bar

{15}{16}Bar baz

{17}{18}Baz|quux
OUT
      assert_equal(expected, contents)

    end
  end
end

