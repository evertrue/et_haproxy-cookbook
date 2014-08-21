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
  gem 'kitchen-ec2',
    github: 'test-kitchen/kitchen-ec2',
    tag: 'e7f840f927518b0f9e29914205c048a463de654e'
end

group :test, :vagrant do
  gem 'kitchen-vagrant', '~> 0.14'
end
