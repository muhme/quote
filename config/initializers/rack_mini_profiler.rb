require 'rack-mini-profiler'

Rack::MiniProfiler.config.pre_authorize_cb = lambda { |env| true }
if Rails.env == "production"
  Rack::MiniProfiler.config.authorization_mode = :allow_authorized # only super admin
else # development or test
  Rack::MiniProfiler.config.authorization_mode = :allow_all
end
Rack::MiniProfiler.config.enable_hotwire_turbo_drive_support = true
