# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestScanCartonLabelOrPallet < Minitest::Test
    include Crossbeams::Responses

    def test_scan_pallet
      BaseRepo.any_instance.stubs(:get_id).returns(1)
      valid_9_digit_pallet_numbers.each do |scanned_number|
        res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: scanned_number)
        assert res.success, 'Should be able to scan a pallet'
        assert_equal scanned_number, res.instance.scanned_number
        assert_equal scanned_number[-9, 9], res.instance.formatted_number
        assert_equal 1, res.instance.pallet_id
        assert_nil res.instance.carton_label_id
      end

      valid_18_digit_pallet_numbers.each do |scanned_number|
        res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: scanned_number)
        assert res.success, 'Should be able to scan a pallet'
        assert_equal scanned_number, res.instance.scanned_number
        assert_equal scanned_number[-18, 18], res.instance.formatted_number
        assert_equal 1, res.instance.pallet_id
        assert_nil res.instance.carton_label_id
      end
    end

    def test_scan_pallet_empty_number_fail
      res = MesscadaApp::ScanCartonLabelOrPallet.call('')
      refute res.success, 'should fail validation'
    end

    def test_scan_pallet_fail
      res = MesscadaApp::ScanCartonLabelOrPallet.call(invalid_pallet_number)
      refute res.success, 'should fail validation'
    end

    def test_scan_pallet_with_carton_number_fail
      res = MesscadaApp::ScanCartonLabelOrPallet.call(pallet_number: valid_carton_number)
      refute res.success, 'should fail validation'
    end

    def test_scan_carton
      BaseRepo.any_instance.stubs(:get_id).returns(1)
      scanned_number = valid_carton_number
      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: scanned_number)
      assert res.success, 'Should be able to scan a carton'
      assert_equal scanned_number, res.instance.scanned_number
      assert_equal scanned_number, res.instance.formatted_number
      assert_equal 1, res.instance.carton_label_id
      assert_nil res.instance.pallet_id
    end

    def test_scan_carton_with_mode
      BaseRepo.any_instance.stubs(:get_id).returns(1)
      scanned_number = valid_carton_number
      res = MesscadaApp::ScanCartonLabelOrPallet.call(carton_label_id: scanned_number)
      assert res.success, 'Should be able to scan a carton'
      assert_equal scanned_number, res.instance.scanned_number
    end

    def test_scan_carton_fail
      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: invalid_carton_number)
      refute res.success, 'should fail validation'
    end

    def test_scan_legacy_carton
      BaseRepo.any_instance.stubs(:get_value).returns(1)
      scanned_number = valid_legacy_carton_number
      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: scanned_number)
      assert res.success, 'Should be able to scan a legacy carton'
      assert_equal scanned_number, res.instance.scanned_number
      assert_equal scanned_number, res.instance.formatted_number
      assert_equal 1, res.instance.carton_label_id
      assert_nil res.instance.pallet_id
    end

    def test_scan_legacy_carton_with_mode
      BaseRepo.any_instance.stubs(:get_value).returns(1)
      scanned_number = valid_legacy_carton_number
      res = MesscadaApp::ScanCartonLabelOrPallet.call(legacy_carton_number: scanned_number)
      assert res.success, 'Should be able to scan a legacy carton'
      assert_equal scanned_number, res.instance.scanned_number
    end

    def test_scan_legacy_carton_fail
      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: invalid_legacy_carton_number)
      refute res.success, 'should fail validation'
    end

    private

    def valid_9_digit_pallet_numbers
      [
        Faker::Number.number(digits: 9).to_s, # Valid pallet numbers have 9 or 18 digits.
        "46#{Faker::Number.number(digits: 9)}", # Last 9 digits. Number is prefixed with "46", "47", "48" or "49".
        "47#{Faker::Number.number(digits: 9)}", # Last 9 digits. Number is prefixed with "46", "47", "48" or "49".
        "48#{Faker::Number.number(digits: 9)}", # Last 9 digits. Number is prefixed with "46", "47", "48" or "49".
        "49#{Faker::Number.number(digits: 9)}", # Last 9 digits. Number is prefixed with "46", "47", "48" or "49".
        "]C#{Faker::Number.number(digits: 13)}" # 15 digits returns Last 9 digits. Number starts with "]C".
      ]
    end

    def valid_18_digit_pallet_numbers
      [
        Faker::Number.number(digits: 18).to_s, # Valid pallet numbers have 18 digits.
        "0#{Faker::Number.number(digits: 18)}", # 18 digits prefixed with "0".
        Faker::Number.number(digits: 20).to_s, # 20 digits - discard the (variable) prefix and use the last 18 digits.
        Faker::Number.number(digits: 21).to_s, # 21 digits - discard the (variable) prefix and use the last 18 digits.
        Faker::Number.number(digits: 23).to_s # 23 digits - discard the (variable) prefix and use the last 18 digits.
      ]
    end

    def invalid_pallet_number
      Faker::Number.number(digits: 3).to_s
    end

    def valid_carton_number
      Faker::Number.number(digits: 7).to_s
    end

    def invalid_carton_number
      Faker::Number.number(digits: 8).to_s
    end

    def valid_legacy_carton_number
      Faker::Number.number(digits: 12).to_s
    end

    def invalid_legacy_carton_number
      Faker::Number.number(digits: 13).to_s
    end
  end
end
