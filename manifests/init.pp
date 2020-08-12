# == Class: autofs
#
# Manage autofs
#
class autofs (
  $browse_mode                = 'NO',
  $timeout                    = '600',
  $negative_timeout           = '60',
  $mount_wait                 = '-1',
  $umount_wait                = '12',
  $mount_nfs_default_protocol = '4',
  $append_options             = 'yes',
  $logging                    = 'none',
  $maps                       = undef,
  $maps_hiera_merge           = false,
  $autofs_package             = 'DEFAULT',
  $autofs_sysconfig           = 'DEFAULT',
  $autofs_service             = 'DEFAULT',
  $autofs_auto_master         = 'DEFAULT',
  $use_nis_maps               = true,
  $use_dash_hosts_for_net     = true,
  $nis_master_name            = 'auto.master',
  $service_ensure             = 'running',
  $service_enable             = true,
) {

  case $::osfamily {
    'RedHat': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/sysconfig/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
      $auto_master_template       = 'autofs/master.erb'
    }
    'Suse': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/sysconfig/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
      $auto_master_template       = 'autofs/master.erb'
    }
    'Debian': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/default/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
      $auto_master_template       = 'autofs/master.erb'
    }
    'Solaris': {
      $autofs_package_default     = 'SUNWatfsr'
      $autofs_sysconfig_default   = '/etc/default/autofs'
      $autofs_auto_master_default = '/etc/auto_master'
      $autofs_sysconfig_template  = 'autofs/autofs_solaris.erb'
      $auto_master_template       = 'autofs/master_solaris.erb'
    }
    default: {
      fail("Operating system family ${::osfamily} is not supported")
    }
  }

  if $autofs_package == 'DEFAULT' {
    $autofs_package_real = $autofs_package_default
  } else {
    $autofs_package_real = $autofs_package
  }
  if $autofs_service == 'DEFAULT' {
    $autofs_service_real = 'autofs'
  } else {
    $autofs_service_real = $autofs_service
  }
  if $autofs_sysconfig == 'DEFAULT' {
    $autofs_sysconfig_real = $autofs_sysconfig_default
  } else {
    $autofs_sysconfig_real = $autofs_sysconfig
  }
  if $autofs_auto_master == 'DEFAULT' {
    $autofs_auto_master_real = $autofs_auto_master_default
  } else {
    $autofs_auto_master_real = $autofs_auto_master
  }

  if is_string($use_nis_maps) {
    $use_nis_maps_real = str2bool($use_nis_maps)
  } else {
    $use_nis_maps_real = $use_nis_maps
  }
  validate_bool($use_nis_maps_real)

  if is_string($use_dash_hosts_for_net) {
    $use_dash_hosts_for_net_real = str2bool($use_dash_hosts_for_net)
  } else {
    $use_dash_hosts_for_net_real = $use_dash_hosts_for_net
  }
  validate_bool($use_dash_hosts_for_net_real)

  validate_string($nis_master_name)

  if is_string($maps_hiera_merge) {
    $maps_hiera_merge_real = str2bool($maps_hiera_merge)
  } else {
    $maps_hiera_merge_real = $maps_hiera_merge
  }
  validate_bool($maps_hiera_merge_real)

  if $maps_hiera_merge_real == true {
    $maps_real = hiera_hash('autofs::maps', undef)
  } else {
    $maps_real = $maps
  }

  validate_re($service_ensure,
    '^running$|^stopped$', "service_ensure must be running or stopped, got ${service_ensure}")

  if is_string($service_enable) {
    $service_enable_real = str2bool($service_enable)
  } else {
    $service_enable_real = $service_enable
  }
  validate_bool($service_enable_real)

  package { 'autofs':
    ensure => installed,
    name   => $autofs_package_real,
  }

  file { 'autofs_sysconfig':
    ensure  => file,
    path    => $autofs_sysconfig_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($autofs_sysconfig_template),
    require => Package['autofs'],
  }

  file { 'auto.master':
    ensure  => file,
    path    => $autofs_auto_master_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($auto_master_template),
    require => Package['autofs'],
  }

  if $maps_real != undef {
    create_resources('autofs::map', $maps_real)
  }

  service { 'autofs':
    ensure    => $service_ensure,
    name      => $autofs_service_real,
    enable    => $service_enable_real,
    require   => Package['autofs'],
    subscribe => [
      File['autofs_sysconfig'],
      File['auto.master'],
    ],
  }
}
