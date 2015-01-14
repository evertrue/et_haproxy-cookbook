source 'https://rubygems.org'

group :test, :development do
  gem 'rake'
end

group :test do
  gem 'berkshelf',  '~> 3.2'
  gem 'chefspec',   '~> 4.1'
  gem 'foodcritic', '~> 4.0'
  gem 'rubocop',    '~> 0.27'

  gem 'fog', '~> 1.24'
end

group :test, :integration do
  gem 'test-kitchen',
      github: 'test-kitchen/test-kitchen',
      tag: '8e4ed89f405a2bf68cd51b7289dcadc783eadd2b'
  gem 'kitchen-ec2',
      github: 'test-kitchen/kitchen-ec2',
      tag: '12b7719249007963a4f65a41454e81a5e474389b'
end

group :test, :vagrant do
  gem 'kitchen-vagrant', '~> 0.15'
end
