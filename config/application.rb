require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Quote
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # default host for URLs used in mailer
    config.action_mailer.default_url_options = { :host => 'www.zitat-service.de' }

    # delete trailing slashes from URLs, found on https://davepeiris.com/blog/trailing-slashes-rails, modfied to Rack::Sendfile, see rails middleware
    config.middleware.insert_before(Rack::Sendfile, Rack::Rewrite) do
      r301 %r{^/(.*)/$}, '/$1'
    end

    # see https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails
    config.exceptions_app = self.routes
  end
end
