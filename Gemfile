source 'http://rubygems.org'

ruby '1.9.3'

gem 'rails', '3.2.13'

# To use debugger
# gem 'ruby-debug'

# Gems used only for assets and not required  
# in production environments by default.  
group :assets do  
  gem 'coffee-rails', "~> 3.2.2"
  gem 'uglifier'
  gem 'asset_sync'
end  

gem 'sass-rails'
gem 'compass-rails'

gem 'jquery-rails'

# Bundle the extra gems:

# gem 'heroku' install the Heroku toolbelt (https://toolbelt.heroku.com/) instead (as gem had some problems)
#gem 'thin'
gem 'unicorn', "~>4.6.3"

gem "mysql2"
gem 'haml'
gem 'sass', "  ~> 3.2.9"
gem 'database_cleaner'
gem 'rest-client', '>= 1.6.0'
gem 'acts-as-taggable-on'
gem 'paperclip'
gem 'delayed_paperclip'
gem 'aws-sdk'
gem "will_paginate"
gem 'dalli'
gem "memcachier"
gem 'kgio', "~>2.8.0"
gem 'thinking-sphinx', "~>2.0.14", :require => 'thinking_sphinx'
gem 'flying-sphinx', "~>0.8.5"
gem 'recaptcha'
gem 'delayed_job', "~>3.0.5"
gem 'delayed_job_active_record'
gem 'json', "~>1.8.0"
gem 'multi_json', "~>1.7.3" # 1.8.0 caused "invalid byte sequence in UTF-8" at heroku
gem 'russian'
gem 'web_translate_it'
gem 'postmark-rails' # could be removed as not currently used
gem 'rails-i18n'
gem 'devise', "~>2.2.4"  #3.0rc requires bit bigger changes
gem "devise-encryptable"
gem "omniauth-facebook"
gem 'spreadsheet'
gem 'rabl'
gem 'rake'
gem 'xpath'
gem 'dynamic_form'
gem "truncate_html"
gem 'money-rails'
gem 'mercury-rails'
gem 'fb-channel-file'
gem 'country_select'
gem 'localized_country_select', '>= 0.9.3'
gem 'mangopay'
gem 'braintree'
gem "mail_view", "~> 1.0.3"

#ouisharelabs
gem 'rdf-turtle'

group :staging do
  gem "airbrake", "~>3.1.12"
  gem 'newrelic_rpm', "~>3.6.2.96"
end

group :production do
  gem "airbrake", "~>3.1.12"
  gem 'newrelic_rpm', "~>3.6.2.96"
end

group :development do
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'rb-fsevent',       require: false
  gem 'guard-rspec',      require: false
  gem 'zeus'
end

group :test do
  gem "rspec-rails"
  gem 'capybara'
  gem 'cucumber-rails', :require => false
  gem 'cucumber' 
  gem 'selenium-webdriver'
  gem 'launchy'
  gem 'ruby-prof'
  gem 'factory_girl_rails'
  gem "pickle"
  gem 'email_spec'
  gem 'action_mailer_cache_delivery'
  gem "parallel_tests", :group => :development
  gem 'timecop'
  gem 'rack-test'
end

