# == Class: transmission::service
#
# Manages the transmission-daemon service and configuration replacement
#
# == Actions:
#
# None
#
# === Authors:
#
# Craig Watson <craig@cwatson.org>
#
# === Copyright:
#
# Copyright (C) Craig Watson
# Published under the Apache License v2.0
#
class transmission::service {

  $config_dir = $::transmission::params::config_dir

  exec { 'replace_transmission_config':
    command     => "${::transmission::params::stop_cmd}\
    && cp -a ${config_dir}/settings.json.puppet ${config_dir}/settings.json\
    && ${::transmission::params::start_cmd}",
    refreshonly => true,
  }

  if $facts['service_provider'] == 'systemd' {
    if $::transmission::params::use_systemd == true {

      file { '/etc/systemd/system/transmission-daemon.service':
        ensure  => file,
        require => Package['transmission-daemon'],
        content => template('transmission/systemd.erb'),
        notify  => Exec['transmission_systemctl_daemon_reload'],
      }

      exec { 'transmission_systemctl_daemon_reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
        require     => File['/etc/systemd/system/transmission-daemon.service'],
        notify      => Service['transmission-daemon'],
      }

      Service['transmission-daemon']{
        require => Exec['transmission_systemctl_daemon_reload'],
      }

    } else {
      file { '/etc/default/transmission-daemon':
        ensure  => file,
        content => template('transmission/default.erb'),
        notify  => Service['transmission-daemon'],
      }
    }
  } else {
    notify{"Not a systemd system, can't manage service or defaults file": }
  }

  if $::transmission::service_ensure == 'running' {
    File <| title == "${config_dir}/settings.json.puppet" |> {
      notify => Exec['replace_transmission_config'],
    }


    Exec <| title == 'transmission_download_blocklists' |> {
      require => Exec['replace_transmission_config'],
    }
  }
  if $facts['service_provider'] == 'freebsd' {
    service { 'transmission':
      ensure => $::transmission::service_ensure,
      enable => $::transmission::service_enable,
    }
  } else {
    service { 'transmission-daemon':
      ensure => "running",
      enable => true,
    }
  }
}
