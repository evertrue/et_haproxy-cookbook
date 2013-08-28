## 2.3.2:

* [OPS-233] - Switch to logrotate_app resource to handle log rotation
* [OPS-235] - Fix how redirect policies work for apps with multiple ACLs

## 2.3.1:

* Fix versioning in changelog
* Fix handling of target FQDN for SSL redirects
* Broke out redirect list builder to a library function
* Move syslog-config code to its own recipe
* Fix broken reference to syslog recipe
* Fix incorrect reference to "api_haproxy" in template

## 2.3.0

* Set up clusters using recipes with search
* Add "or" ACL clauses to use_backend code (oops!)
* Include `apt` recipe on Debian-family machines

## 2.2.0:

* Allow for "or" ACL clauses
* Fix a bug created by adding (!) to acl names

## 2.1.0:

* Fixed how redirect fqdn's are printed
* Made it possible to use negating (!) ACLs

## 2.0.1:

* Enhanced ACL parsing
* Removed some config attribute redundancy

## 1.0.3:

* Don't log haproxy messages to the regular syslog

## 1.0.2:

* Added changelog
* Fixed syslog integration
