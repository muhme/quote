# Ensure Authlogic modules are included even if User was loaded before DB became available.
# (Needed for Rails 8.1.3 update)
Rails.application.config.to_prepare do
  user_model = "User".safe_constantize
  next unless user_model
  next if user_model.method_defined?(:password=)

  begin
    # Refresh columns first: Authlogic checks DB setup before including modules.
    user_model.reset_column_information
    user_model.acts_as_authentic

    if user_model.method_defined?(:password=)
      Rails.logger.info("Authlogic repaired for User: password= is now available")
    else
      Rails.logger.warn("Authlogic repair attempted for User, but password= is still unavailable")
    end
  rescue StandardError => e
    Rails.logger.warn("Authlogic repair skipped: #{e.class}: #{e.message}")
  end
end
