# Create the Database to contain the RCU
class role::db::rcudb()
{
  contain ::profile::base
  contain ::profile::db::os
  contain ::profile::db::software
  contain ::profile::db::rcudb

  Class['::profile::base::hosts']
  -> Class['::profile::db::os']
  -> Class['::profile::db::software']
  -> Class['::profile::db::rcudb']
}
