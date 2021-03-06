# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestProductSetupRoutes < RouteTester

  INTERACTOR = ProductionApp::ProductSetupInteractor

  def test_edit
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::ProductSetup
    ensure_exists!(INTERACTOR)
    Production::ProductSetups::ProductSetup::Edit.stub(:call, bland_page) do
      get 'production/product_setups/product_setups/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/product_setups/product_setups/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Production::ProductSetups::ProductSetup::Show.stub(:call, bland_page) do
      get 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_product_setup).returns(ok_response(instance: row_vals))
    patch_as_fetch 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_product_setup).returns(bad_response)
    Production::ProductSetups::ProductSetup::Edit.stub(:call, bland_page) do
      patch_as_fetch 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::ProductSetup
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_product_setup).returns(ok_response)
    delete_as_fetch 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::ProductSetup
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_product_setup).returns(bad_response)
    delete_as_fetch 'production/product_setups/product_setups/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(ProductionApp::ProductSetupTemplateInteractor)
    Production::ProductSetups::ProductSetup::New.stub(:call, bland_page) do
      get  'production/product_setups/product_setup_templates/1/product_setups/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(ProductionApp::ProductSetupTemplateInteractor)
    get 'production/product_setups/product_setup_templates/1/product_setups/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(ProductionApp::ProductSetupTemplateInteractor)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_product_setup).returns(ok_response(instance: row_vals))
    post_as_fetch 'production/product_setups/product_setup_templates/1/product_setups', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    # expect_json_add_to_grid(has_notice: true)
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(ProductionApp::ProductSetupTemplateInteractor)
    INTERACTOR.any_instance.stubs(:create_product_setup).returns(bad_response)
    Production::ProductSetups::ProductSetup::New.stub(:call, bland_page) do
      post_as_fetch 'production/product_setups/product_setup_templates/1/product_setups', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    # expect_json_replace_dialog
  end
end
