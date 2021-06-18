# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestScanCartonOrPallet < Minitest::Test
    include Crossbeams::Responses

    def test_scan_pallet
      BaseRepo.any_instance.stubs(:get_id).returns(1)
      valid_9_digit_pallet_numbers.each do |scanned_number|
        res = MesscadaApp::ScanCartonOrPallet.call(scanned_number)
        assert res.success, 'Should be able to scan a pallet'
        assert_equal scanned_number, res.instance[:scanned_number]
        assert_equal '123456789', res.instance[:formatted_number]
        assert_equal 1, res.instance.pallet_id
        assert_nil res.instance.carton_id
      end

      valid_18_digit_pallet_numbers.each do |scanned_number|
        res = MesscadaApp::ScanCartonOrPallet.call(scanned_number)
        assert res.success, 'Should be able to scan a pallet'
        assert_equal scanned_number, res.instance[:scanned_number]
        assert_equal '123456789123456789', res.instance[:formatted_number]
        assert_equal 1, res.instance.pallet_id
        assert_nil res.instance.carton_id
      end
    end

    def test_scan_pallet_empty_number_fail
      res = MesscadaApp::ScanCartonOrPallet.call('')
      refute res.success, 'should fail validation'
    end

    def test_scan_pallet_fail
      res = MesscadaApp::ScanCartonOrPallet.call(invalid_pallet_number, :pallet)
      refute res.success, 'should fail validation'
    end

    def test_scan_pallet_with_carton_number_fail
      res = MesscadaApp::ScanCartonOrPallet.call(valid_carton_number, :pallet)
      refute res.success, 'should fail validation'
    end

    def test_scan_carton
      BaseRepo.any_instance.stubs(:get_id).returns(1)
      res = MesscadaApp::ScanCartonOrPallet.call(valid_carton_number)
      assert res.success, 'Should be able to scan a carton'
      assert_equal valid_carton_number, res.instance[:scanned_number]
      assert_equal valid_carton_number, res.instance[:formatted_number]
      assert_equal 1, res.instance.carton_id
      assert_nil res.instance.pallet_id
    end

    def test_scan_carton_with_mode
      BaseRepo.any_instance.stubs(:get_id).returns(1)

      res = MesscadaApp::ScanCartonOrPallet.call(valid_carton_number, :carton)
      assert res.success, 'Should be able to scan a carton'
      assert_equal valid_carton_number, res.instance[:scanned_number]
    end

    def test_scan_carton_fail
      res = MesscadaApp::ScanCartonOrPallet.call(invalid_carton_number)
      refute res.success, 'should fail validation'
    end

    def test_scan_legacy_carton
      BaseRepo.any_instance.stubs(:get_id).returns(1)

      res = MesscadaApp::ScanCartonOrPallet.call(valid_legacy_carton_number)
      assert res.success, 'Should be able to scan a legacy carton'
      assert_equal valid_legacy_carton_number, res.instance[:scanned_number]
      assert_equal valid_legacy_carton_number, res.instance[:formatted_number]
      assert_equal 1, res.instance.carton_id
      assert_nil res.instance.pallet_id
    end

    def test_scan_legacy_carton_with_mode
      BaseRepo.any_instance.stubs(:get_id).returns(1)

      res = MesscadaApp::ScanCartonOrPallet.call(valid_legacy_carton_number, :legacy_carton)
      assert res.success, 'Should be able to scan a legacy carton'
      assert_equal valid_legacy_carton_number, res.instance[:scanned_number]
    end

    def test_scan_legacy_carton_fail
      res = MesscadaApp::ScanCartonOrPallet.call(invalid_legacy_carton_number, :legacy_carton)
      refute res.success, 'should fail validation'
    end

    private

    def valid_9_digit_pallet_numbers
      [
        '123456789', # Valid pallet numbers have 9 or 18 digits.
        '46123456789', # Last 9 digits. Number is prefixed with "46", "47", "48" or "49".
        '47123456789',
        '48123456789',
        '49123456789',
        ']C1234123456789' # Last 9 digits. Number starts with "C".
      ]
    end

    def valid_18_digit_pallet_numbers
      [
        '123456789123456789', # Valid pallet numbers have 18 digits.
        '0123456789123456789', # 18 digits prefixed with "0".
        '01123456789123456789', # 20 digits - discard the (variable) prefix and use the last 18 digits.
        '012123456789123456789', # 21 digits - discard the (variable) prefix and use the last 18 digits.
        '01234123456789123456789' # 23 digits - discard the (variable) prefix and use the last 18 digits.
      ]
    end

    def invalid_pallet_number
      '123'
    end

    def valid_carton_number
      '1234567'
    end

    def invalid_carton_number
      '12345678'
    end

    def valid_legacy_carton_number
      '123456789012'
    end

    def invalid_legacy_carton_number
      '1234567890123'
    end
  end
end
