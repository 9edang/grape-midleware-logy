require 'logger'
require 'grape'
require_relative 'timing'

module Grape
  module Middleware
    class Logy < Grape::Middleware::Globals
      if defined?(ActiveRecord)
        ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          Timing.append_db_runtime(event)
        end
      end
    
      BACKSLASH = '/'.freeze
    
      attr_reader :logger
    
      class << self
        attr_accessor :logger, :filter, :headers, :condensed, :time_type
    
        def default_logger
          default = Logger.new(STDOUT)
          default.formatter = ->(*args) { args.last.to_s << "\n".freeze }
          default
        end

        def register_status_exception(&block)
          yield(self)
        end

        def register(klass, status)
          @@status_exceptions[klass] = status
        end
      end
    
      def initialize(_, options = {})
        super
        @options[:filter] ||= self.class.filter
        @options[:headers] ||= self.class.headers
        @logger = options[:logger] || self.class.logger || self.class.default_logger
      end

      def call!(env)
        @env = env
        before
        error = catch(:error) do
          begin
            @app_response = @app.call(@env)
          rescue => e
            after_exception(e)
            raise e
          end
          nil
        end
        if error
          after_failure(error)
          throw(:error, error)
        else
          status, _, _ = *@app_response
          after(status)
        end
        @app_response
      end
    
      def before
        reset_db_runtime
        start_time
        super
    
        logger.info ""
        logger.info %Q(Started %s "%s" at %s) % [
          env[Grape::Env::GRAPE_REQUEST].request_method,
          env[Grape::Env::GRAPE_REQUEST].path,
          start_time.to_s
        ]
        logger.info %Q(Processing by #{processed_by})
        logger.info %Q(  Parameters: #{parameters})
        logger.info %Q(  Headers: #{headers}) if @options[:headers]
        logger.info ""
      end

      def after_exception(e)
        logger.warn("\xF0\x9F\x92\xA5 #{e.class.name}: #{e.message}")
        status = begin
          e.status
        rescue
          self.class.class_variable_get(:@@status_exceptions)[e.class.name] || 500
        end
        after(status)
      end
    
      def after_failure(error)
        logger.warn("\xF0\x9F\x92\xA5 Error: #{error[:message]}") if error[:message]
        after(error[:status])
      end

      def after(status)
        stop_time
        quering_duration = ms_to_round_sec(db_runtime)

        logger.info ""
        logger.info %Q(Completed %s in %s s (ActiveRecord: %s s | View: %s s)) % [
          status,
          ms_to_round_sec(total_runtime),
          quering_duration,
          ms_to_round_sec(view_runtime)
        ]
        logger.warn "\xF0\x9F\x94\xA5 Please refactor your query couse its too slow" if quering_duration > 2.0
        logger.info ""
      end
    
      def parameters
        request_params = env[Grape::Env::GRAPE_REQUEST_PARAMS].to_hash
        request_params.merge! env[Grape::Env::RACK_REQUEST_FORM_HASH] if env[Grape::Env::RACK_REQUEST_FORM_HASH]
        request_params.merge! env['action_dispatch.request.request_parameters'] if env['action_dispatch.request.request_parameters']
        if @options[:filter]
          @options[:filter].filter(request_params)
        else
          request_params
        end
      end
    
      def headers
        request_headers = env[Grape::Env::GRAPE_REQUEST_HEADERS].to_hash
        return Hash[request_headers.sort] if @options[:headers] == :all
    
        headers_needed = Array(@options[:headers])
        result = {}
        headers_needed.each do |need|
          result.merge!(request_headers.select { |key, value| need.to_s.casecmp(key).zero? })
        end
        Hash[result.sort]
      end
    
      def processed_by
        endpoint = env[Grape::Env::API_ENDPOINT]
        result = []
        if endpoint.namespace == BACKSLASH
          result << ''
        else
          result << endpoint.namespace
        end
        result.concat endpoint.options[:path].map { |path| path.to_s.sub(BACKSLASH, '') }
        endpoint.options[:for].to_s << result.join(BACKSLASH)
      end

      private
      @@status_exceptions = {}
      def total_runtime
        ((stop_time - start_time) * 1000)
      end
    
      def view_runtime
        total_runtime - db_runtime
      end
    
      def start_time
        @start_time ||= Time.zone.now
      end
    
      def stop_time
        @stop_time ||= Time.zone.now
      end
    
      def reset_db_runtime
        Timing.reset_db_runtime
      end
    
      def db_runtime
        Timing.db_runtime.round(2)
      end
    
      def ms_to_round_sec(ms)
        Timing.ms_to_round_sec(ms)
      end
    end
  end
end

require_relative 'logy/railtie' if defined?(Rails)