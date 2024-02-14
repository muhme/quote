# config/initializers/locale.rb

# where the I18n library should search for translation files
I18n.load_path += Dir[Rails.root.join('config', 'locales', '*.yml')]

# permitted locales available to the five supported
I18n.available_locales = [:de, :en, :es, :ja, :uk]

# set default locale explicity, even :en is already the default
I18n.default_locale = :en

# set fallbacks explicity
I18n.fallbacks.map(de: :en, es: :en, ja: :en, uk: :en);
