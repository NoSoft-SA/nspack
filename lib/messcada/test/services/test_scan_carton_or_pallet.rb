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
        assert_equal '123456789', res.instance[:scanned_number]
      end

      valid_18_digit_pallet_numbers.each do |scanned_number|
        res = MesscadaApp::ScanCartonOrPallet.call(scanned_number)
        assert res.success, 'Should be able to scan a pallet'
        assert_equal '123456789123456789', res.instance[:scanned_number]
      end
    end

    def test_scan_pallet_fail
      res = MesscadaApp::ScanCartonOrPallet.call('1234567891234567890')
      refute res.success, 'should fail validation'
    end

    def test_scan_carton
      BaseRepo.any_instance.stubs(:get_id).returns(1)

      res = MesscadaApp::ScanCartonOrPallet.call('1234567')
      assert res.success, 'Should be able to scan a carton'
      assert_equal '1234567', res.instance[:scanned_number]
    end

    def test_scan_carton_fail
      res = MesscadaApp::ScanCartonOrPallet.call('12345678')
      refute res.success, 'should fail validation'
    end

    def test_scan_legacy_carton
      BaseRepo.any_instance.stubs(:get_id).returns(1)

      res = MesscadaApp::ScanCartonOrPallet.call('123456789012')
      assert res.success, 'Should be able to scan a legacy carton'
      assert_equal '123456789012', res.instance[:scanned_number]
    end

    def test_scan_legacy_carton_fail
      res = MesscadaApp::ScanCartonOrPallet.call('1234567890123')
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
  end
end
