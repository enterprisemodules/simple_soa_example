# TODO: Docs
class profile::db () {
  user { 'root':
    ensure   => present,
    password => '$1$/.ao8McI$lpqBMpiaiJ5TN93Qa2ufG/',
  }

  File { '/srv/rcu_kill_sessions.sql':
    ensure    => file,
    source    => 'puppet:///modules/profile/rcu_kill_sessions.sql',
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    backup    => false,
    show_diff => false,
  }
}
