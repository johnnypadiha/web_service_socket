source 'https://rubygems.org'

gem 'colorize'
group :development do
  # gem 'capistrano', '~> 3.4.0'
  gem 'eventmachine'
  gem 'logging'
  gem 'activesupport'#, '~> 4.2', '>= 4.2.6'
end

group :test do
  gem 'rspec'
  gem 'shoulda'#, '~> 3.5.0'
  gem 'shoulda-matchers', github: 'thoughtbot/shoulda-matchers'
  gem 'rspec-collection_matchers'#, '~> 1.1.2'
  gem 'minitest', '~> 5.9.0'
end

group :production do
  gem 'puma'
  gem 'activerecord'
  gem 'pg'
end
