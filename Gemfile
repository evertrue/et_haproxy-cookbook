source 'https://rubygems.org'

group :test, :development do
  gem 'rake'
  gem 'coveralls', require: false
end

group :test do
  gem 'berkshelf',  '~> 3.0'
  gem 'chefspec',   '~> 3.0'
  gem 'foodcritic', '~> 3.0'
  gem 'rubocop',    '~> 0.23'

  gem 'fog', '~> 1.20'
  gem 'rspec', '~> 2.14.0'
end

group :test, :integration do
  gem 'test-kitchen',    '~> 1.1'
  gem 'kitchen-vagrant', '~> 0.14'
  gem 'kitchen-ec2',     '>= 0.8'
end
