require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Quote
  # catch ActionController::BadRequest from Rack, see #54
  # set params[bad_request] as flag which will be handled by bad_request?() with HTTP 404, and note the reason as well
  # not calling static_pages/bad_request directly as ChatGPT says:
  #   "Calling a controller method from a middleware is not considered a best practice in Rails and is generally
  #    discouraged, as it breaks the separation of concerns between the middleware and the controller layers."
  class HandleBadRequests
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue => e #  ActionController::BadRequest from Rack::QueryParser::InvalidParameterError
      Rails.logger.error "Middleware Error Exception=#{e.message}"
      env["QUERY_STRING"] = "bad_request=" + CGI.escape(e.message) + "!"
      @app.call(env)
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # default host for URLs used in mailer
    config.action_mailer.default_url_options = { :host => "www.zitat-service.de" }

    # last handle ActionController::BadRequest exceptions from Rack
    config.middleware.use Quote::HandleBadRequests

    # delete trailing slashes from URLs, found on https://davepeiris.com/blog/trailing-slashes-rails,
    # modfied to Rack::Sendfile, see rails middleware
    config.middleware.insert_before Rack::Sendfile, Rack::Rewrite do
      r301 %r{^/(.*)/$}, "/$1"
    end

    # see https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails
    config.exceptions_app = self.routes

    # having own log format with datetime and severity
    Rails.logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
    Rails.logger.formatter = proc do |severity, time, progname, msg|
      formatted_time = time.strftime("%y%m%d %H:%M:%S.%L") # include milliseconds
      # %y%m%d %H:%M:%S.%L'   INFO message, e.g.
      # 230723 15:08:20.544   INFO Completed 200 OK in 322ms
      "#{formatted_time} #{severity.rjust(7)} #{msg}\n"
    end

    # using caching in all stages
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }

    # Make to_time preserve the full timezone (Europe/Berlin) rather than just the offset (+01:00),
    # which is the new default behavior in Rails 8.1.
    config.active_support.to_time_preserves_timezone = :zone
  end
end
