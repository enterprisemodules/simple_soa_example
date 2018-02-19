# Apply required OS settings for a database node
class profile::db::os
{
  mount { '/dev/shm':
    ensure  => present,
    atboot  => true,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'size=3500m',
  }


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

  $groups = ['oinstall','dba' ,'oper' ]

  group { $groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure     => present,
    uid        => 600,
    gid        => 'oinstall',
    groups     => $groups,
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => '/home/oracle',
    comment    => 'This user oracle was created by Puppet',
    require    => Group[$groups],
    managehome => true,
  }

  $packages = [ 'binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
                'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64', 'gcc.x86_64',
                'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
                'sysstat.x86_64','unixODBC-devel','glibc.i686']

  package { $packages:
    ensure  => present,
  }

  limits::limits { '*/nofile':
    soft => '2048',
    hard => '8192',
  }
  limits::limits { 'oracle/nofile':
    soft => '65536',
    hard => '65536',
  }
  limits::limits { 'oracle/nproc':
    soft => '2048',
    hard => '16384',
  }
  limits::limits { 'oracle/stack':
    soft => '10240',
    hard => '32768',
  }
  limits::limits { 'grid/nofile':
    soft => '65536',
    hard => '65536',
  }
  limits::limits { 'grid/nproc':
    soft => '2048',
    hard => '16384',
  }
  limits::limits { 'grid/stack':
    soft => '10240',
    hard => '32768',
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', value => '1048576',}
}
