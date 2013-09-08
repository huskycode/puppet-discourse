class discourse {
  $db_username = "discourse"
  $db_password = "db_password"
  $server_name = "discourse.huskycode.com"
  $user_home = "/home/discourse"

  class { 'apt': }
  include postgresql::server
  include postgresql::contrib
  include rvm
  class { 'nginx': }
  
  File { 
  }

  Package {
    ensure => 'present'
  }
  package { "openssh-server": }
  
  #These are packages instructed to be install
  package { ["git","libtool","libpq-dev","gawk","pngcrush"]: }    

  apt::ppa { 'ppa:rwky/redis': }
  package { 'redis-server': 
    require => Apt::Ppa["ppa:rwky/redis"],
  }
  postgresql::role { $db_username: 
    superuser => true,
    login => true,
    password_hash => $db_password,
    require => Class["postgresql::server"],
  }
  postgresql::database{'discourse_prod':
    owner => $db_user,
    require => Class["postgresql::server"],
  }
  postgresql::database_grant { 'discourse_prod':
    privilege => 'ALL',
    db        => 'discourse_prod',
    role      => $db_username,
    require   => Postgresql::Role[$db_username],
  }


  group { 'discourse': 
    ensure => 'present',
  }
  user { 'discourse':
    ensure => 'present',
    shell => '/bin/bash',
    home => $user_home,
 managehome => true,
    require => [Group["discourse"]]
  }

  file { ["/var/www"]:
    ensure => 'directory',
    owner => 'discourse', 
    group => 'discourse', 
    mode => "0755",
    require => User["discourse"]
  }

  rvm::system_user { "discourse": }
  rvm_system_ruby { 'ruby-2.0.0':
      ensure => 'present',
      default_use => true,
      require => Rvm::System_user["discourse"],
  }
  rvm_gem { ["ruby-2.0.0/bundler"]: 
    ensure => "1.3.5",
    require => Rvm_system_ruby["ruby-2.0.0"],
  }
  rvm_gem { ["ruby-2.0.0/bluepill"]: 
    ensure => "0.0.66",
    require => Rvm_system_ruby["ruby-2.0.0"],
  }

  vcsrepo { "/var/www/discourse":
    ensure => present,
    provider => git,
    source => "git://github.com/discourse/discourse.git",
    user => "discourse",
    revision => "latest-release",
    require => [User["discourse"],File["/var/www"]]
  }

  exec { "bundle_install":
    command => "/usr/local/rvm/bin/rvm 2.0.0 do bundle install --deployment --without test",
    cwd => "/var/www/discourse", 
    user => "discourse",
    require => Vcsrepo["/var/www/discourse"],
  }

  file { "/etc/nginx/conf.d/discourse.conf": 
    ensure => "file",
    content => template("discourse/discourse.conf.erb"),
    require => [Vcsrepo["/var/www/discourse"]],
    owner => "discourse",
    group => "discourse",
    mode => "0755",
    notify => Service["nginx"],
  }
  file { "/var/www/discourse/config/database.yml": 
    ensure => "file",
    content => template("discourse/database.yml.erb"),
    require => Vcsrepo["/var/www/discourse"],
    owner => "discourse",
    group => "discourse",
    mode => "0755",
  }
  file { "/var/www/discourse/config/discourse.pill": 
    ensure => "file",
    content => template("discourse/discourse.pill.erb"),
    require => Vcsrepo["/var/www/discourse"],
    owner => "discourse",
    group => "discourse",
    mode => "0755",
  }
  file { "/var/www/discourse/config/environments/production.rb": 
    ensure => "file",
    content => template("discourse/production.rb.erb"),
    require => Vcsrepo["/var/www/discourse"],
    owner => "discourse",
    group => "discourse",
    mode => "0755",
  }
  file { "/var/www/discourse/config/redis.yml": 
    ensure => "file",
    source => "puppet:///modules/discourse/redis.yml",
    require => Vcsrepo["/var/www/discourse"],
    owner => "discourse",
    group => "discourse",
    mode => "0755",
  } 

  exec { "db migrate":
    command => "/usr/local/rvm/bin/rvm 2.0.0 do rake db:migrate",
    environment => ["RUBY_GC_MALLOC_LIMIT=90000000","RAILS_ENV=production"],
    cwd => "/var/www/discourse", 
    user => "discourse",
    require => [Exec["bundle_install"], File["/var/www/discourse/config/database.yml"]], 
  } #->
  #exec { "asset precompile":
  #  command => "/usr/local/rvm/bin/rvm 2.0.0 do rake assets:precompile",
  #  environment => ["RUBY_GC_MALLOC_LIMIT=90000000","RAILS_ENV=production"],
  #  cwd => "/var/www/discourse", 
  #  user => "discourse",
  #  logoutput => true,
  #}
  exec { "bootup_bluepill":
    command => "rvm wrapper $(rvm current) bootup bluepill",
    user => "discourse",
    creates => "/usr/local/nvm/bin/bootup_bluepill",
    path => "/bin:/usr/bin:/usr/local/rvm/bin",
    require => [Exec["bundle_install"], File["/var/www/discourse/config/database.yml"]], 
  } ->
  exec { "bootup_bundle":
    command => "rvm wrapper $(rvm current) bootup bundle",
    user => "discourse",
    creates => "/usr/local/nvm/bin/bootup_bundle",
    path => "/bin:/usr/bin:/usr/local/rvm/bin",
    require => [Exec["bundle_install"], File["/var/www/discourse/config/database.yml"]], 
  } -> 
  file { "/home/discourse/.bash_aliases":
    owner => "discourse",
    content => 'alias bluepill="NOEXEC_DISABLE=1 bluepill --no-privileged -c ~/.bluepill"'
  } -> 
cron { bluepill:
  command => "RUBY_GC_MALLOC_LIMIT=90000000 RAILS_ROOT=/var/www/discourse RAILS_ENV=production NUM_WEBS=2 /home/discourse/.rvm/bin/bootup_bluepill --no-privileged -c ~/.bluepill load /var/www/discourse/config/discourse.pill",
  user    => 'discourse',
  ensure => "present",
  special => 'reboot',
}

}
