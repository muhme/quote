# Ensure Authlogic modules are included even if User was loaded before DB became available.
# (Needed for Rails 8.1.3 update)
Rails.application.config.to_prepare do
  next unless defined?(User)
  next if User.method_defined?(:password=)

  begin
    User.acts_as_authentic
    Rails.logger.info("Authlogic repaired for User: password= is now available") if User.method_defined?(:password=)
  rescue StandardError => e
    Rails.logger.warn("Authlogic repair skipped: #{e.class}: #{e.message}")
  end
end
