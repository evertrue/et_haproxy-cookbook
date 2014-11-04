source 'https://rubygems.org'

group :test, :development do
  gem 'rake'
  gem 'coveralls', require: false
end

group :test do
  gem 'berkshelf',  '~> 3.1.5'
  gem 'chefspec',   '~> 4.1'
  gem 'foodcritic', '~> 4.0'
  gem 'rubocop',    '~> 0.26'
  gem 'serverspec', '~> 2.3'

  gem 'fog', '~> 1.24'
end

group :test, :integration do
  gem 'test-kitchen',
      github: 'test-kitchen/test-kitchen',
      tag: '459238b88ccb4219d8bcabd5a89a8adcb7391b16'
  gem 'kitchen-ec2',
      github: 'test-kitchen/kitchen-ec2',
      tag: 'e7f840f927518b0f9e29914205c048a463de654e'
end

group :test, :vagrant do
  gem 'kitchen-vagrant', '~> 0.15'
end
