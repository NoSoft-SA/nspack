# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/security/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/security/interactors/*.rb"].each { |f| require f }
Dir["#{root_dir}/security/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/security/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/security/validations/*.rb"].each { |f| require f }
Dir["#{root_dir}/security/views/**/*.rb"].each { |f| require f }

module SecurityApp
end
