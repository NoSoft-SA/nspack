require './webapp.rb'

# EXAMPLE of quick+dirty debug middleware:
#
# class WrapRck
#   def initialize(app)
#     @app = app
#   end
#
#   def call(env)
#     status, head, body = @app.call(env)
#     p ">>> |||RACK||| body: #{env['PATH_INFO']}"
#     # p body.first.encoding unless body.empty?
#     body.each { |b| p b.encoding } if env['PATH_INFO'].include?('/labels')
#     [status, head, body]
#   end
# end
# use WrapRck

# Guard against Sequel's connection dropping when passenger smart spawning is in use.
# See https://www.phusionpassenger.com/library/indepth/ruby/spawn_methods/#am-i-responsible-for-reestablishing-database-connections-after-the-preloader-has-forked-a-child-process
# http://sequel.jeremyevans.net/rdoc/files/doc/code_order_rdoc.html#label-Disconnect+If+Using+Forking+Webserver+with+Code+Preloading
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode.
      MessageBus.after_fork
      # - disconnect in the parent so the parent's db connection is not shared in the child processes.
      DB.disconnect
      # - disconnect all dataminer DB connections.
      DM_CONNECTIONS.disconnect_all
    end
  end
end

if ENV['MINI_PROFILER']
  p 'Rack::MiniProfiler'
  use Rack::MiniProfiler
  Rack::MiniProfiler.config.position = 'bottom-left'
  Rack::MiniProfiler.config.skip_paths = [/debug/, /messcada/, /terminus/]
  Rack::MiniProfiler.config.authorization_mode = :allow_authorized
end

run Nspack
