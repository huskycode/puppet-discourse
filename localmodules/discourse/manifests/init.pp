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
    require => Class["postgresql::server"],
  }

  group { 'discourse': 
    ensure => 'present',
  }
  user { 'discourse':
    ensure => 'present',
    shell => '/bin/bash',
    require => [Group["discourse"]], #, Class["nginx"]],
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
    logoutput => true,
    require => Vcsrepo["/var/www/discourse"],
  }    
}
