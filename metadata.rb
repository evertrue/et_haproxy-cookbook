name             'et_haproxy'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'All rights reserved'
description      'Installs/Configures et_haproxy'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '3.4.2'

depends 'apt'
depends 'openssl'
depends 'logrotate', '~> 1.5'
depends 'et_fog', '~> 1.0'
depends 'stunnel', '~> 2.0'
depends 'certificate', '~> 0.5'
depends 'newrelic_meetme_plugin', '~> 0.0.3'
depends 'sudo', '~> 2.7'
depends 'et_users', '~> 1.4'
depends 'et_security', '~> 1.2'
