name             'et_haproxy'
maintainer       'EverTrue, Inc.'
maintainer_email 'eric.herot@evertrue.com'
license          'All rights reserved'
description      'Installs/Configures et_haproxy'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.5.0'

depends 'apt'
depends 'openssl'
depends 'logrotate'
depends 'et_fog', '= 1.0.1'
