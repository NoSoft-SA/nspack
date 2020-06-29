# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestGovtInspectionSheetRoutes < RouteTester

  INTERACTOR = FinishedGoodsApp::GovtInspectionSheetInteractor

  def test_edit
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet
    ensure_exists!(INTERACTOR)
    FinishedGoods::Inspection::GovtInspectionSheet::Edit.stub(:call, bland_page) do
      get 'finished_goods/inspection/govt_inspection_sheets/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/inspection/govt_inspection_sheets/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    FinishedGoods::Inspection::GovtInspectionSheet::Show.stub(:call, bland_page) do
      get 'finished_goods/inspection/govt_inspection_sheets/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/inspection/govt_inspection_sheets/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_govt_inspection_sheet).returns(ok_response(instance: row_vals))
    patch_as_fetch 'finished_goods/inspection/govt_inspection_sheets/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_govt_inspection_sheet).returns(bad_response)
    FinishedGoods::Inspection::GovtInspectionSheet::Edit.stub(:call, bland_page) do
      patch_as_fetch 'finished_goods/inspection/govt_inspection_sheets/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_govt_inspection_sheet).returns(ok_response)
    patch_as_fetch 'finished_goods/inspection/govt_inspection_sheets/1/delete', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_flash_notice
  end

  def test_delete_fail
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_govt_inspection_sheet).returns(bad_response)
    patch_as_fetch 'finished_goods/inspection/govt_inspection_sheets/1/delete', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_flash_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    FinishedGoods::Inspection::GovtInspectionSheet::New.stub(:call, bland_page) do
      get  'finished_goods/inspection/govt_inspection_sheets/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/inspection/govt_inspection_sheets/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_govt_inspection_sheet).returns(bad_response)
    FinishedGoods::Inspection::GovtInspectionSheet::New.stub(:call, bland_page) do
      post_as_fetch 'finished_goods/inspection/govt_inspection_sheets', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
