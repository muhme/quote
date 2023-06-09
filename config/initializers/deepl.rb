require "deepl"

if ENV["DEEPL_API_KEY"].present?
  begin
    DeepL.configure do |config|
      config.auth_key = ENV["DEEPL_API_KEY"]
      config.host = "https://api-free.deepl.com"
      config.version = "v2"
    end
  rescue DeepL::Exceptions::Error => e
    Rails.logger.error("DeepL configuration error: #{e.message}")
  end
else
  Rails.logger.warn("DEEPL_API_KEY environment variable is not set. DeepL services will not be available.")
end
