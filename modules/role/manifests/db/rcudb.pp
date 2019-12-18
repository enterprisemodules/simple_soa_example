# Create the Database to contain the RCU
class role::db::rcudb()
{
  contain ::profile::base
  contain ::ora_profile::database

  Class['::profile::base']
  -> Class['::ora_profile::database']
}
