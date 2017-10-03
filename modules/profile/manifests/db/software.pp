# Install the Oracle software
class profile::db::software(
  $version,
  $file_name,
  $type,
)
{
  include ::profile
  include ::profile::db

  ora_install::installdb{$file_name:
    version                   => $version,
    file                      => $file_name,
    database_type             => $type,
    oracle_base               => $profile::db::base,
    oracle_home               => $profile::db::home,
    puppet_download_mnt_point => $profile::source_dir,
  }

}
