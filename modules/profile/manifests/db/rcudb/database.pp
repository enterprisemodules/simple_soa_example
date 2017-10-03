# Create the Darabase
class profile::db::rcudb::database()
{
  require profile::db
  #
  # All standard values fetched in data function
  #
  ora_database{$profile::db::dbname:
    ensure                 => present,
    oracle_base            => $profile::db::base,
    oracle_home            => $profile::db::home,
    control_file           => 'reuse',
    system_password        => $profile::db::system_password,
    sys_password           => $profile::db::sys_password,
    character_set          => 'AL32UTF8',
    national_character_set => 'AL16UTF16',
    extent_management      => 'local',
    logfile_groups => [
        {file_name => 'demo1.log', size => '512M', reuse => true},
        {file_name => 'demo2.log', size => '512M', reuse => true},
      ],
    default_tablespace => {
      name      => 'USERS',
      datafile  => {
        file_name  => 'users.dbs',
        size       => '50M',
        reuse      =>  true,
        autoextend => {next => '10M', maxsize => 'unlimited'}
      },
      extent_management => {
        'type'        => 'local',
        autoallocate  => true,
      }
    },
    datafiles       => [
      {file_name   => 'demo1.dbs', size => '100M', reuse => true, autoextend => {next => '100M', maxsize => 'unlimited'}},
    ],
    default_temporary_tablespace => {
      name      => 'TEMP',
      'type'    => 'bigfile',
      tempfile  => {
        file_name  => 'tmp.dbs',
        size       => '100M',
        reuse      =>  true,
        autoextend => {
          next    => '50M',
          maxsize => 'unlimited',
        }
      },
    },
    undo_tablespace   => {
      name      => 'UNDOTBS',
      'type'    => 'bigfile',
      datafile  => {
        file_name  => 'undo.dbs',
        size       => '100M',
        reuse      =>  true,
        autoextend => {next => '50M', maxsize => 'unlimited'}      }
    },
    timezone       => '+01:00',
    sysaux_datafiles => [
      {file_name   => 'sysaux1.dbs', size => '100M', reuse => true, autoextend => {next => '50M', maxsize => 'unlimited'}},
    ],
  } ->

  ora_install::dbactions{ "start_${profile::db::dbname}":
    oracle_home => $profile::db::home,
    db_name     => $profile::db::dbname,
  } ->

  ora_install::autostartdatabase{ 'autostart oracle':
    oracle_home => $profile::db::home,
    db_name     => $profile::db::dbname,
  } ->

  file{'/tmp': ensure => 'directory'} ->

  ora_install::net{ 'config net8':
    oracle_home  => $profile::db::home,
    version      => '12.1',        # Different version then the oracle version
    download_dir => '/tmp',
  } ->

  ora_install::listener{'start listener':
    oracle_base  => $profile::db::base,
    oracle_home  => $profile::db::home,
    action       => 'start',
  }

  ora_service{"demo.example.com@${profile::db::dbname}":
    ensure => present,
  } ->
  ora_service{"demo@${profile::db::dbname}":
    ensure => present,
  }

}
