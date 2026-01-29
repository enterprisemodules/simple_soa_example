# A regular SOA managed server
class role::soa::node () {
  contain profile::base
  contain wls_profile::node

  Class['profile::base']
  -> Class['wls_profile::node']
}
