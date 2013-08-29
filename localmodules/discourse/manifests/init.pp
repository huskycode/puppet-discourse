class discourse {
  $db_password = "db_password"

  class { 'apt': }
  include postgresql::server
  include rvm
  #class { 'nginx': }
  
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

  postgresql::database_user{'discourse':
    password_hash => $db_password, 
  }

  group { 'discourse': 
    ensure => 'present',
  }
  user { 'discourse':
    ensure => 'present',
    shell => '/bin/bash',
    require => [Group["discourse"]], #, Class["nginx"]],
  }

  file { ["/var/www","/var/www/discourse"]: 
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
  }
}
