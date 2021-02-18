require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestCommonHelpers < Minitest::Test
  include CommonHelpers

  def test_make_options
    [
      { in: [1, 2, 3], out: ['<option value="1">1</option>', '<option value="2">2</option>', '<option value="3">3</option>'].join("\n") },
      { in: [['one', 1], ['two', 2], ['three', 3]], out: ['<option value="1">one</option>', '<option value="2">two</option>', '<option value="3">three</option>'].join("\n") },
      { in: ['one', 'two', 'three'], out: ['<option value="one">one</option>', '<option value="two">two</option>', '<option value="three">three</option>'].join("\n") }
    ].each { |a| assert_equal a[:out], make_options(a[:in]) }
  end

  def test_select_attributes
    instance = { one: 1, two: 2 }
    row_keys = %i[one two]
    assert_equal instance, select_attributes(instance, row_keys)
    assert_equal({ one: 1, two: 2, three: 3 }, select_attributes(instance, row_keys, three: 3))
    assert_equal({ one: 1, two: 22, three: 3 }, select_attributes(instance, row_keys, three: 3, two: 22))

    # Automatic unpacking of extended_columns:
    instance = { one: 1, two: 2, extended_columns: { red: 1, blue: 2 } }
    assert_equal({ one: 1, two: 2, red: 1, blue: 2 }, select_attributes(instance, row_keys))
    assert_equal({ one: 1, two: 2, three: 3, red: 1, blue: 2 }, select_attributes(instance, row_keys, three: 3))
  end

  def test_base_validation
    assert_equal({ base: ['Err'] }, add_base_validation_errors({}, 'Err'))
    assert_equal({ fld1: ['must be filled'], base: ['Err'] }, add_base_validation_errors({fld1: ['must be filled']}, 'Err'))
    assert_equal({ base: ['Err-1', 'Err-2'] }, add_base_validation_errors({}, ['Err-1', 'Err-2']))
    assert_equal({ base: ['Err-3', 'Err-1', 'Err-2'] }, add_base_validation_errors({base: ['Err-3']}, ['Err-1', 'Err-2']))
  end

  def test_base_validation_with_highlights
    assert_equal({ base_with_highlights: { messages: ['Err'], highlights: :fld1 } },
                 add_base_validation_errors_with_highlights({}, 'Err', :fld1))
    assert_equal({ fld1: ['must be filled'], base_with_highlights: { messages: ['Err'], highlights: [:fld1, :fld2] } },
                 add_base_validation_errors_with_highlights({fld1: ['must be filled']}, 'Err', [:fld1, :fld2]))
    assert_equal({ base_with_highlights: { messages: ['Err-1', 'Err-2'], highlights: :fld1 } },
                 add_base_validation_errors_with_highlights({}, ['Err-1', 'Err-2'], :fld1))
    assert_equal({ base_with_highlights: { messages: ['Err-3', 'Err-1', 'Err-2'], highlights: [:fld1, :fld2] } },
                 add_base_validation_errors_with_highlights({ base_with_highlights: { messages: ['Err-3'], highlights: :fld1 } }, ['Err-1', 'Err-2'], :fld2))
  end

  def test_move_validation_errors_to_base
    assert_equal({ base: ['Fld1 Err'] }, move_validation_errors_to_base({ fld1: 'Err' }, [:fld1]))

    msg = { fld1: ['Not ok', 'Other'] }
    exp = { base: ['Fld1 Not ok', 'Fld1 Other'] }
    assert_equal exp, move_validation_errors_to_base(msg, :fld1)

    msg = { fld1: ['Not ok', 'Other'], fld2: ['Err'] }
    exp = { base: ['Fld1 Not ok', 'Fld1 Other'], fld2: ['Err'] }
    assert_equal exp, move_validation_errors_to_base(msg, :fld1)

    msg = { fld1: ['Not ok', 'Other'], fld2: ['Err'] }
    exp = { base: ['Fld1 Not ok', 'Fld1 Other', 'Fld2 Err'] }
    assert_equal exp, move_validation_errors_to_base(msg, [:fld1, :fld2])

    msg = { fld1: ['Err'] }
    exp = { base_with_highlights: { messages: ['Err'], highlights: [:fld1, :fld2] } }
    assert_equal exp, move_validation_errors_to_base(msg, :fld1, highlights: { fld1: [:fld1, :fld2] })
  end

  def test_load_via_json
    plain = { loadNewUrl: '/test' }.to_json
    with_notice = { loadNewUrl: '/test', flash: {notice: 'NOTE' } }.to_json
    assert_equal plain, load_via_json('/test')
    assert_equal with_notice, load_via_json('/test', notice: 'NOTE')
  end

  def test_reload_previous_dialog_via_json
    plain = { reloadPreviousDialog: '/test' }.to_json
    with_notice = { reloadPreviousDialog: '/test', flash: {notice: 'NOTE' } }.to_json
    assert_equal plain, reload_previous_dialog_via_json('/test')
    assert_equal with_notice, reload_previous_dialog_via_json('/test', notice: 'NOTE')
  end
end
