# VM instance at NoSoft offices
server '192.168.50.27', user: 'nsld', roles: %w[app db web]
set :deploy_to, '/home/nsld/nspack'
set :chruby_ruby, 'ruby-2.5.0'
