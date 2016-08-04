#
# Simple manifest to simulate Puppet's 'pluginsync'.
# This is needed in a masterless setup to copy facts, types, providers, etc to
# Puppet's library.
#
file { $::settings::libdir:
  ensure  => 'directory',
  source  => 'puppet:///plugins',
  recurse => true,
  purge   => true,
  backup  => false,
}
