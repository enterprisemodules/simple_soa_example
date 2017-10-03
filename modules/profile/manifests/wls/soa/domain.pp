#
# This profile class create's a full running soa domain. It's purpose is to be used inside a profile
# defining a WebLogic domain and it's contents
#
# @example useage inside a role class
#   include profile::wls::soa::domain
#
# @param  domain_name [String] the name to use for the domain
# @param  admin_server_arguments [Array] An Array of strings containing the arguments to be passed to the Admin Server
# @param  servers [Hash] A HAsh of servers and Machines
# @param  repository_database_url [String] use following syntax jdbc:oracle:thin:@//hostname:1521/serviename
# @param  rcu_database_url [String] Use following syntax hostname:1521:service
# @param  repository_prefix [String] The prefix to use when creating RCU database users
# @param  repository_password [String] The password used when creating the RCU repository
# @param  repository_sys_password [String] The sys password of the database.
#
class profile::wls::soa::domain(
  String  $domain_name,
  Array   $admin_server_arguments,
  Hash    $servers,
  String  $cluster_name,
  String  $repository_database_url,
  String  $rcu_database_url,
  String  $repository_prefix,
  String  $repository_password,
  String  $repository_sys_password,
)
{

  require ::profile::wls

  #
  # For consistency, you can specify here what kind of domain and clusters you want
  # Theses settings ara then applied to both the creation of the domain and to the
  # conversion of the domain. Change them the way you need them.
  #
  $bpm_enabled = false # true|false
  $bam_enabled = false  # true|false
  $osb_enabled = false # true|false
  $soa_enabled = true  # true|false
  $oam_enabled = false # true|false
  $oim_enabled = false # true|false
  $b2b_enabled = false # true|false
  $ess_enabled = false # true|false

  #
  # Some general usage variables
  #
  $wls_log_dir = "${profile::wls::domains_dir}/${domain_name}/servers/logs"
  $server_array      = sort(keys($servers))
  $defaults          = {
    domain_name      => $domain_name,
    nodemanager_port => $profile::wls::nodemanager_port,
    server_arguments => [
      '-XX:PermSize=64m',
      '-Xms768m',
      '-Xmx768m',
    ],
    require          => Wls_adminserver['soa/AdminServer'],
    before           => Wls_cluster['soa/SoaCluster'],
  }

  #
  # This statement creates all machines and WebLogic servers. The content of
  # the $servers variable are read through hiera. Here you ca decide if your configuration
  # is a single node system or a multi-node cluster. The nodes and machines them selfs are
  # created after the domain is created.
  #
  create_resources('wls_install::cluster_node', $servers, $defaults)

  #
  # Here you create your domain. The domain is the first thing a WebLogic installation needs. Here
  # you also decide what kind of domain you need. A bare WebLogic
  #
  wls_install::domain{'soa':
    domain_name                          => $domain_name,
    version                              => $profile::wls::version,
    wls_domains_dir                      => $profile::wls::domains_dir,
    # wls_apps_dir                         => $profile::wls::apps_dir,
    domain_template                      => 'soa',
    bam_enabled                          => $bam_enabled,
    b2b_enabled                          => $b2b_enabled,
    ess_enabled                          => $ess_enabled,
    development_mode                     => false,
    adminserver_listen_on_all_interfaces => false,
    adminserver_address                  => $profile::wls::adminserver_address,
    adminserver_port                     => $profile::wls::adminserver_port,
    nodemanager_address                  => $profile::wls::nodemanager_address,
    nodemanager_port                     => $profile::wls::nodemanager_port,
    repository_database_url              => $repository_database_url,
    rcu_database_url                     => $rcu_database_url,
    repository_prefix                    => $repository_prefix,
    repository_password                  => 'welcome01',
    repository_sys_password              => $repository_sys_password,
    log_output                           => false,  # When debugging, set this to true
  } ->

  #
  # Over here you define the nodemanager. Here you can specify the address
  # the nodemanager is running on and the listen address. When you create multiple domains
  # with multiple nodemanagers, you have to specify different addresses and/or ports.
  #
  wls_install::nodemanager{"nodemanager for ${domain_name}":
    domain_name         => $domain_name,
    version             => $profile::wls::version,
    nodemanager_address => $profile::wls::nodemanager_address,
    nodemanager_port    => $profile::wls::nodemanager_port,
    log_dir             => "${wls_log_dir}/nodemanager",
    sleep               => 25,
  } ->

  #
  # Before you can manage any WebLogic objects, you'll need to have a running admin server.
  # This code makes sure the admin server is started. Just like with the nodemanager, you'll need
  # to specify unique addresses and ports.
  #
  wls_install::control{"start_adminserver_${domain_name}":
    action              => 'start',
    domain_name         => $domain_name,
    adminserver_address => $profile::wls::adminserver_address,
    adminserver_port    => $profile::wls::adminserver_port,
    nodemanager_port    => $profile::wls::nodemanager_port,
    weblogic_user       => $profile::wls::weblogic_user,
    weblogic_password   => $profile::wls::weblogic_password,
    os_user             => $profile::wls::os_user,
  } ->

  #
  # wls_setting is used to store the credentials and connect URL of a domain. The Puppet
  # types need this to connect to the admin server and change settings.
  #
  wls_setting{'soa':
    user              => $profile::wls::os_user,
    weblogic_user     => $profile::wls::weblogic_user,
    weblogic_password => $profile::wls::weblogic_password,
    connect_url       => "t3://${profile::wls::adminserver_address}:${profile::wls::adminserver_port}",
    weblogic_home_dir => $profile::wls::weblogic_home_dir,
    post_classpath    => "${profile::wls::middleware_home_dir}/oracle_common/modules/oracle.jps_12.1.3/jps-wls-trustprovider.jar:${profile::wls::middleware_home_dir}/oracle_common/modules/internal/features/jrf_wlsFmw_oracle.jrf.wlst_12.1.3.jar",
  } ->

  #
  # You can use this wls_server definition to change any settings for your
  # Admin server. because the AdminServer is restarted by wls_adminserver{'soa/AdminServer':}
  # These settings are immediately applied
  #
  wls_server{'soa/AdminServer':
    ensure                      => 'present',
    arguments                   => $admin_server_arguments,
    listenaddress               => $profile::wls::adminserver_address,
    listenport                  => $profile::wls::adminserver_port,
    machine                     => 'LocalMachine',
    logfilename                 => "${wls_log_dir}/AdminServer/AdminServer_${domain_name}.log",
    log_datasource_filename     => "${wls_log_dir}/AdminServer/datasource.log",
    log_http_filename           => "${wls_log_dir}/AdminServer/access.log",
    log_file_min_size           => '2000',
    log_filecount               => '10',
    log_number_of_files_limited => '1',
    log_rotate_logon_startup    => '1',
    log_rotationtype            => 'bySize',
    log_http_format_type        => 'common',
    log_http_format             => 'date time cs-method cs-uri sc-status',
  } ~>

  #
  # This definition restarts the Admin server. It is a refresh-only, so it is only done
  # when the statement before actually changed something.
  #
  wls_adminserver{'soa/AdminServer':
    ensure              => running,
    refreshonly         => true,
    server_name         => 'AdminServer',
    domain_name         => $domain_name,
    domain_path         => "${profile::wls::domains_dir}/${domain_name}",
    os_user             => $profile::wls::os_user,
    nodemanager_address => $profile::wls::nodemanager_address,
    nodemanager_port    => $profile::wls::nodemanager_port,
    weblogic_user       => $profile::wls::weblogic_user,
    weblogic_password   => $profile::wls::weblogic_password,
    weblogic_home_dir   => $profile::wls::weblogic_home_dir,
    subscribe           => Wls_install::Domain['soa'],
  } ->

  #
  # This is the cluster definition. The server array is extracted from the list of servers
  # and machines,
  #
  wls_cluster{'soa/SoaCluster':
    ensure         => 'present',
    messagingmode  => 'unicast',
    migrationbasis => 'consensus',
    servers        => $server_array,
  } ->

  #
  # This definition changes current servers and cluster setup into a correct
  # Fusion Middleware setup. If you change this, make sure the ..._enabled settings are the
  # same as the one you set when creating the domain.
  #
  wls_install::utils::fmwcluster{'Soacluster':
    domain_name         => $domain_name,
    repository_prefix   => $repository_prefix,
    soa_cluster_name    => 'SoaCluster',
    bam_cluster_name    => 'SoaCluster',
    ess_cluster_name    => 'SoaCluster',
    adminserver_address => $profile::wls::adminserver_address,
    adminserver_port    => $profile::wls::adminserver_port,
    nodemanager_port    => $profile::wls::nodemanager_port,
    bam_enabled         => $bam_enabled,
    bpm_enabled         => $bpm_enabled,
    soa_enabled         => $soa_enabled,
    osb_enabled         => $osb_enabled,
    b2b_enabled         => $b2b_enabled,
    ess_enabled         => $ess_enabled,
    log_output          => false,  # When debugging, set this to true
  } ->
  #
  # This resource definition pack's the current definition of the domain. This packed domain file
  # can be used by other nodes in the cluster. They fetch it, unpack it and use it to enter the domain.
  # When the node is part of the domain, the packed file loses its value. Any changes in the domain are managed
  # by webLogic.
  #
  wls_install::packdomain{$domain_name:
    weblogic_home_dir   => $profile::wls::weblogic_home_dir,
    middleware_home_dir => $profile::wls::middleware_home_dir,
    jdk_home_dir        => $profile::wls::jdk_home_dir,
    wls_domains_dir     => $profile::wls::domains_dir,
    domain_name         => $domain_name,
    os_user             => $profile::wls::os_user,
    os_group            => $profile::wls::os_group,
    download_dir        => '/data/install',
    log_output          => false,       # Use true when you are debugging
  } ->

  #
  # This class create's a startup script in /etc/init.d.
  #
  wls_install::support::nodemanagerautostart{'soa_nodemanager':
    version     => $profile::wls::version,
    wl_home     => $profile::wls::weblogic_home_dir,
    user        => $profile::wls::os_user,
    domain      => $domain_name,
    domain_path => "${profile::wls::domains_dir}/${domain_name}",
  } ->

  #
  # For now we will put the file in the vagrant directory for sharing. In a real enterprise environment
  # You can use ssh or a shared nfs folder.
  #
  file{"/vagrant/domain_${domain_name}.jar":
    ensure => present,
    source => "/data/install/domain_${domain_name}.jar",
  }
}
