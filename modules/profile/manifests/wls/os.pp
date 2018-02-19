# operating settings for Middleware
class profile::wls::os {

  require ::profile::wls

  case ($::os['release']['major']) {
    '4','5','6': { $firewall_service = 'iptables'}
    '7': { $firewall_service = 'firewalld' }
    default: { fail 'unsupported OS version when checking firewall service'}
  }

  service { $firewall_service:
    ensure    => false,
    enable    => false,
    hasstatus => true,
  }

  group { $profile::wls::os_group :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = weblogic
  user { $profile::wls::os_user :
    ensure     => present,
    groups     => $profile::wls::os_group,
    shell      => '/bin/bash',
    password   => '$1$mloDctBy$tvcYSIqP4a1yzOVV/JwxY0',
    home       => "/home/${profile::wls::os_user}",
    comment    => 'wls user created by Puppet',
    managehome => true,
    require    => Group[$profile::wls::os_group],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64']


  package { $install:
    ensure  => present,
  }

  $limits_defaults = {
    ensure  => 'present',
    user    => "${profile::wls::os_user}",
  }

  $default_limits = {
    '*_nofile' => {
      'user'       => '*',
      'limit_type' => 'nofile',
      'hard'       => '8192',
      'soft'       => '2048',
    },
    "${profile::wls::os_user}_nofile" => {
      'limit_type' => 'nofile',
      'hard'       => '65536',
      'soft'       => '65536',
    },
    "${profile::wls::os_user}_nproc" => {
      'limit_type' => 'nproc',
      'hard'       => '16384',
      'soft'       => '2048',
    },
    "${profile::wls::os_user}_stack" => {
      'limit_type' => 'stack',
      'soft'       => '10240',
    },
  }

  create_resources('limits::limits', $default_limits, $limits_defaults)

  $sysctl = {
    'kernel.msgmnb' => {ensure => 'present', value => '65536',},
    'kernel.msgmax' => {ensure => 'present', value => '65536',},
    'kernel.shmmax' => {ensure => 'present', value => '2588483584',},
    'kernel.shmall' => {ensure => 'present', value => '2097152',},
    'fs.file-max' => {ensure => 'present', value => '6815744',},
    'net.ipv4.tcp_keepalive_time' => {ensure => 'present', value => '1800',},
    'net.ipv4.tcp_keepalive_intvl' => {ensure => 'present', value => '30',},
    'net.ipv4.tcp_keepalive_probes' => {ensure => 'present', value => '5',},
    'net.ipv4.tcp_fin_timeout' => {ensure => 'present', value => '30',},
    'kernel.shmmni' => {ensure => 'present', value => '4096',},
    'fs.aio-max-nr' => {ensure => 'present', value => '1048576',},
    'kernel.sem' => {ensure => 'present', value => '250 32000 100 128',},
    'net.ipv4.ip_local_port_range' => {ensure => 'present', value => '9000 65500',},
    'net.core.rmem_default' => {ensure => 'present', value => '262144',},
    'net.core.rmem_max' => {ensure => 'present', value => '4194304',},
    'net.core.wmem_default' => {ensure => 'present', value => '262144',},
    'net.core.wmem_max' => {ensure => 'present', value => '1048576',},
  }

  create_resources('sysctl', $sysctl)

}
