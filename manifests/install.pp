# == Class: transmission::install
#
# Installs packages
#
# == Actions:
#
# * Conditionally adds the Transmission Apt PPA to the system
# * Installs packages
# * Optionally downloads blacklists
#
# === Authors:
#
# Craig Watson <craig@cwatson.org>
#
# === Copyright:
#
# Copyright (C) 2014 Craig Watson
# Published under the Apache License v2.0
#
class transmission::install {

  case $facts['os']['name'] {
    'Ubuntu': {
      if $::transmission::manage_ppa {
        apt::ppa { 'ppa:transmissionbt/ppa': }
        Package {
          require => Apt::Ppa['ppa:transmissionbt/ppa']
        }
      }
    }
    default: {
      warning("Unsupported Platform: ${facts['os']['name']}, Can't use PPA")
    }
  }

  #package { ['transmission-cli','transmission-common','transmission-daemon']:
  package { ['transmission-cli', 'transmission-daemon']:
    ensure  => present,
  }

  if $::transmission::blocklist_url != 'http://www.example.com/blocklist' and $::transmission::service_ensure == 'running' {
    exec { 'transmission_download_blocklists':
      command => "${::transmission::params::remote_command} --blocklist-update > /dev/null",
      creates => "${::transmission::params::home_dir}/blocklists/blocklist.bin",
      require => Service['transmission-daemon'],
    }
  }

}
