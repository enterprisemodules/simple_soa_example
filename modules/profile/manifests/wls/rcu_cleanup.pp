# TODO: Docs
class profile::wls::rcu_cleanup () inherits wls_profile::basic_domain::wls_domain {
  $install_type = lookup('wls_profile::install_type')
  if $facts['wls_install_domains'].dig($wls_profile::domain_name,'servers').empty {
    $version      = lookup('wls_profile::weblogic_version')
    $download_dir = $wls_profile::download_dir
    $logoutput    = lookup({ name => 'logoutput', default_value => 'on_failure' })
    $rcu_password = $wls_profile::basic_domain::wls_domain::repository_password

    echo { "Cleanup RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix} using RCU home at ${wls_profile::basic_domain::wls_domain::middleware_home}":
      withpath => false,
    }
    case $install_type {
      'osb','osb_soa','osb_soa_bpm','soa','soa_bpm','bam': {
        $rcu_template_name = 'soa'
      }
      'adf': {
        $rcu_template_name = 'adf'
      }
      'forms': {
        $rcu_template_name = 'forms'
      }
      default: {
        $rcu_template_name = $install_type
      }
    }

    case $rcu_template_name {
      'forms': {
        case $version {
          1036, 1111, 1211, 1212, 1213: {
            fail 'unsupported version'
          }
          default: {
            $components = '-component STB -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS '
            $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
          }
        }
      }
      'adf': {
        case $version {
          1036, 1111, 1211, 1212, 1213: {
            $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component UCSCC '
            $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
          }
          default: {
            $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB '
            $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
          }
        }
      }
      'soa': {
        case $version {
          1036, 1111, 1211, 1212, 1213: {
            $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component UCSCC -component UCSUMS -component UMS -component ESS -component SOAINFRA -component MFT '
            $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
          }
          default: {
            $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component UCSUMS -component ESS -component SOAINFRA '
            $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
          }
        }
      }
      'mft': {
        $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component UCSCC -component MFT -component UCSUMS -component ESS '
        $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
      }
      'bip': {
        $components = '-component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component BIPLATFORM '
        $components_passwords = [$rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password, $rcu_password]
      }
      default: {
        fail("Unrecognized FMW fmw_product ${rcu_template_name}")
      }
    }

    file { "${download_dir}/rcu_passwords_${install_type}_delete_${wls_profile::basic_domain::wls_domain::repository_prefix}.txt":
      ensure    => file,
      content   => epp('wls_install/utils/rcu_passwords.txt.epp', {
          # lint:ignore:strict_indent
          'rcu_sys_password'     => $wls_profile::basic_domain::wls_domain::repository_sys_password,
          'components_passwords' => $components_passwords,
          # lint:endignore:strict_indent
      }),
      mode      => '0600',
      owner     => $wls_profile::basic_domain::wls_domain::os_user,
      group     => $wls_profile::basic_domain::wls_domain::os_group,
      backup    => false,
      show_diff => false,
      before    => Wls_rcu["Remove RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix} for version ${version}"],
    }

    unless ( defined(File["${download_dir}/checkrcu.py"]) ) {
      file { "${download_dir}/checkrcu.py":
        ensure    => file,
        source    => 'puppet:///modules/wls_install/wlst/checkrcu.py',
        mode      => '0775',
        owner     => $wls_profile::basic_domain::wls_domain::os_user,
        group     => $wls_profile::basic_domain::wls_domain::os_group,
        backup    => false,
        show_diff => false,
        before    => Wls_rcu["Remove RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix} for version ${version}"],
      }
    }

    file { "${download_dir}/askpass.sh":
      ensure    => file,
      mode      => '0755',
      content   => 'echo change_on_install',
      show_diff => false,
    }

    file { "${download_dir}/rcu_kill_sessions_${wls_profile::basic_domain::wls_domain::repository_prefix}.sh":
      ensure    => file,
      mode      => '0755',
      content   => epp('profile/rcu_kill_sessions.sh.epp', {
          # lint:ignore:strict_indent
          'schema_prefix' => $wls_profile::basic_domain::wls_domain::repository_prefix,
          # lint:endignore:strict_indent
      }),
      show_diff => false,
    }

    exec { "Kill sessions for RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix}":
      command   => "${download_dir}/rcu_kill_sessions_${wls_profile::basic_domain::wls_domain::repository_prefix}.sh",
      logoutput => $logoutput,
      path      => ['/bin','/usr/bin','/sbin','/usr/sbin'],
      require   => [
        File["${download_dir}/askpass.sh"],
        File["${download_dir}/rcu_kill_sessions_${wls_profile::basic_domain::wls_domain::repository_prefix}.sh"]
      ],
      before    => Wls_rcu["Remove RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix} for version ${version}"],
    }

    wls_rcu { "Remove RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix} for version ${version}":
      ensure       => 'delete',
      prefix       => $wls_profile::basic_domain::wls_domain::repository_prefix,
      statement    => "${wls_profile::basic_domain::wls_domain::middleware_home}/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE -connectString ${wls_profile::basic_domain::wls_domain::rcu_database_url} -dbUser sys -dbRole SYSDBA -schemaPrefix ${wls_profile::basic_domain::wls_domain::repository_prefix} ${components} -f < ${download_dir}/rcu_passwords_${domain_name}_delete_${wls_profile::basic_domain::wls_domain::repository_prefix}.txt",
      os_user      => $wls_profile::basic_domain::wls_domain::os_user,
      oracle_home  => "${wls_profile::basic_domain::wls_domain::middleware_home}/oracle_common",
      sys_user     => 'sys',
      sys_password => $wls_profile::basic_domain::wls_domain::repository_sys_password.unwrap,
      jdbc_url     => $wls_profile::basic_domain::wls_domain::repository_database_url,
      jdk_home_dir => $wls_profile::basic_domain::wls_domain::jdk_home,
      as_sysdba    => 'yes',
      check_script => "${download_dir}/checkrcu.py",
      require      => Exec["Kill sessions for RCU schema ${wls_profile::basic_domain::wls_domain::repository_prefix}"],
    }
  } else {
    echo { "RCU schema cleanup skipped as domain ${$wls_profile::domain_name} already exists":
      withpath => false,
    }
  }
}
