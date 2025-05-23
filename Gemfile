# Gemfile
#
# to check for up-to-date (but also check ruby version is available in CentOS 9 Stream):
#   bundle outdated
#   bundle update

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Puma as the app server
gem 'puma'

gem 'will_paginate', '~> 4.0'
# waiting for https://github.com/binarylogic/authlogic/pull/770
gem "authlogic", github: "binarylogic/authlogic", ref: "refs/pull/770/head"
# for authlogic >= 6
gem "scrypt", "~> 3.0"

# to remove trailing slashes from URLs
gem 'rack-rewrite'

gem 'rails-i18n', '~> 8.0'
gem "mobility", "~> 1.2"

# Terser minifies JavaScript files by wrapping TerserJS to be accessible in Ruby
gem "terser", "~> 1.1"
gem 'deepl-rb', require: 'deepl'

gem 'rack-mini-profiler'
# For call-stack profiling flamegraphs
gem 'stackprof'

# get wikipedia articles
gem 'rest-client'

# for avatar images
gem 'rmagick'
gem 'requestjs-rails'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara'
  gem 'selenium-webdriver'
  # code coverage for Ruby
  gem 'simplecov', require: false
  # find and manage missing and unused translations
  gem 'i18n-tasks', require: false
  # for i18n-tasks translate-missing
  gem 'easy_translate', require: false
  gem 'rubocop', require: false
  gem 'rubocop-i18n', require: false
  gem 'htmlbeautifier' # for erb-formatter
  gem 'erb-formatter', require: false
  gem 'minitest-hooks', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem 'rvt'
  # listens to file modifications and notifies  about the changes
  gem 'listen', '~> 3.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end
