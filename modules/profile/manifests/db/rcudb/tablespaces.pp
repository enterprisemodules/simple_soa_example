# Create tablespaces for this simple database
class profile::db::rcudb::tablespaces(
  String $tablespace_name,
)
{
  include ::profile::db

  ora_tablespace {"${tablespace_name}@${profile::db::dbname}":
    ensure                   => present,
    datafile                 => $tablespace_name,
    size                     => '20M',
    logging                  => yes,
    autoextend               => on,
    next                     => '10M',
    max_size                 => '30M',
    extent_management        => local,
    segment_space_management => auto,
  }

}
