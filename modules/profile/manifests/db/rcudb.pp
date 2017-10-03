# After the software has been installed create the database and
# the tablespaces.
class profile::db::rcudb
{
  contain ::profile::db::rcudb::database
  contain ::profile::db::rcudb::tablespaces

  Class['::profile::db::rcudb::database']
  ->Class['::profile::db::rcudb::tablespaces']
}
