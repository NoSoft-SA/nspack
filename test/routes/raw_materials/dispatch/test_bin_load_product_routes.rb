# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestBinLoadProductRoutes < RouteTester

  LOAD_INTERACTOR = RawMaterialsApp::BinLoadInteractor
  INTERACTOR = RawMaterialsApp::BinLoadProductInteractor

  def test_edit
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::BinLoadProduct
    ensure_exists!(INTERACTOR)
    RawMaterials::Dispatch::BinLoadProduct::Edit.stub(:call, bland_page) do
      get 'raw_materials/dispatch/bin_load_products/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/dispatch/bin_load_products/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    RawMaterials::Dispatch::BinLoadProduct::Show.stub(:call, bland_page) do
      get 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_bin_load_product).returns(ok_response(instance: row_vals))
    patch_as_fetch 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_bin_load_product).returns(bad_response)
    RawMaterials::Dispatch::BinLoadProduct::Edit.stub(:call, bland_page) do
      patch_as_fetch 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::BinLoadProduct
    ensure_exists!(INTERACTOR)
    row_vals = { bin_load_id: 1 }
    INTERACTOR.any_instance.stubs(:delete_bin_load_product).returns(ok_response(instance: row_vals))
    delete_as_fetch 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_delete_fail
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::BinLoadProduct
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_bin_load_product).returns(bad_response)
    delete_as_fetch 'raw_materials/dispatch/bin_load_products/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    ensure_exists!(LOAD_INTERACTOR)
    RawMaterials::Dispatch::BinLoadProduct::New.stub(:call, bland_page) do
      get  'raw_materials/dispatch/bin_loads/1/bin_load_products/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    ensure_exists!(LOAD_INTERACTOR)
    get 'raw_materials/dispatch/bin_loads/1/bin_load_products/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    ensure_exists!(LOAD_INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_bin_load_product).returns(ok_response(instance: row_vals))
    post_as_fetch 'raw_materials/dispatch/bin_loads/1/bin_load_products', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    ensure_exists!(LOAD_INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_bin_load_product).returns(bad_response)
    RawMaterials::Dispatch::BinLoadProduct::New.stub(:call, bland_page) do
      post_as_fetch 'raw_materials/dispatch/bin_loads/1/bin_load_products', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
