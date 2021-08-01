class Grape::Middleware::Logy::Railtie < Rails::Railtie
  options = Rails::VERSION::MAJOR < 5 ? { after: :load_config_initializers } : {}
  initializer 'grape.middleware.logy', options do
    Grape::Middleware::Logy.logger = Rails.application.config.logger || Rails.logger.presence
    parameter_filter_class = if Rails::VERSION::MAJOR >= 6
                               ActiveSupport::ParameterFilter
                             else
                               ActionDispatch::Http::ParameterFilter
                             end
    Grape::Middleware::Logy.filter = parameter_filter_class.new Rails.application.config.filter_parameters
  end
end
