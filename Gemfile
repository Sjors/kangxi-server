source 'https://rubygems.org'
ruby '2.1.0'
gem 'rails', '4.0.2'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder'
# gem 'bootstrap-sass'
gem 'bootstrap-sass', github: 'thomas-mcdonald/bootstrap-sass'
gem 'figaro'
gem 'haml-rails'
gem 'high_voltage'
gem 'simple_form'
gem 'pg'
gem 'ruby-pinyin'
gem 'devise'
gem 'cancan'
gem 'will_paginate'
gem 'zidian', :git => 'git://github.com/Sjors/zidian.git'
gem 'exception_notification'

group :test do
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'rspec-rails'
  gem 'terminal-notifier-guard' # Mac
  gem "factory_girl_rails"
  gem "capybara"
  gem 'poltergeist'
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller', :platforms=>[:mri_19, :rbx]
  gem 'html2haml'
  gem 'quiet_assets'
  gem 'rb-fchange', :require=>false
  gem 'rb-fsevent', :require=>false
  gem 'rb-inotify', :require=>false
  gem 'pry'
end

group :production do
  gem 'rails_12factor'
  # Caching:
  gem 'kgio'
  gem 'dalli'
  gem 'memcachier'
end
