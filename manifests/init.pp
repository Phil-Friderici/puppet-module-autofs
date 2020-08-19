# == Class: autfs
#
# Manage autofs
#
class autofs (
  $browse_mode                = 'NO',
  $timeout                    = 600,
  $negative_timeout           = 60,
  $mount_wait                 = -1,
  $umount_wait                = 12,
  $mount_nfs_default_protocol = 4,
  $append_options             = 'yes',
  $logging                    = 'none',
  $maps                       = {},
  $maps_hiera_merge           = false,
  $autofs_package             = undef,
  $autofs_sysconfig           = undef,
  $autofs_service             = 'autofs',
  $autofs_auto_master         = undef,
  $use_nis_maps               = true,
  $use_dash_hosts_for_net     = true,
  $nis_master_name            = 'auto.master',
  $service_ensure             = 'running',
  $service_enable             = true,
) {

  # system specific default values
  case $::osfamily {
    'RedHat': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/sysconfig/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
    }
    'Suse': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/sysconfig/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
    }
    'Debian': {
      $autofs_package_default     = 'autofs'
      $autofs_sysconfig_default   = '/etc/default/autofs'
      $autofs_auto_master_default = '/etc/auto.master'
      $autofs_sysconfig_template  = 'autofs/autofs.erb'
    }
    'Solaris': {
      $autofs_package_default     = 'SUNWatfsr'
      $autofs_sysconfig_default   = '/etc/default/autofs'
      $autofs_auto_master_default = '/etc/auto_master'
      $autofs_sysconfig_template  = 'autofs/autofs_solaris.erb'

    }
    default: {
      fail("Operating system family ${::osfamily} is not supported")
    }
  }

  # variable preparations
  case $autofs_package {
    undef:   { $autofs_package_real = $autofs_package_default }
    default: { $autofs_package_real = $autofs_package }
  }

  case $autofs_sysconfig {
    undef:   { $autofs_sysconfig_real = $autofs_sysconfig_default }
    default: { $autofs_sysconfig_real = $autofs_sysconfig }
  }

  case $autofs_auto_master {
    undef:   { $autofs_auto_master_real = $autofs_auto_master_default }
    default: { $autofs_auto_master_real = $autofs_auto_master }
  }

  case type3x($timeout) {
    'integer': { $timeout_int = $timeout }
    'string':  { $timeout_int = $timeout + 0}
    default:   { fail('autofs::timeout is not an integer.') }
  }

  case type3x($negative_timeout) {
    'integer': { $negative_timeout_int = $negative_timeout }
    'string':  { $negative_timeout_int = $negative_timeout + 0}
    default:   { fail('autofs::negative_timeout is not an integer.') }
  }

  case type3x($mount_wait) {
    'integer': { $mount_wait_int = $mount_wait }
    'string':  { $mount_wait_int = $mount_wait + 0}
    default:   { fail('autofs::mount_wait is not an integer.') }
  }

  case type3x($umount_wait) {
    'integer': { $umount_wait_int = $umount_wait }
    'string':  { $umount_wait_int = $umount_wait + 0}
    default:   { fail('autofs::umount_wait is not an integer.') }
  }

  case type3x($mount_nfs_default_protocol) {
    'integer': { $mount_nfs_default_protocol_int = $mount_nfs_default_protocol }
    'string':  { $mount_nfs_default_protocol_int = $mount_nfs_default_protocol + 0}
    default:   { fail('autofs::mount_nfs_default_protocol is not an integer.') }
  }

  case type3x($use_nis_maps) {
    'string':  { $use_nis_maps_bool = str2bool($use_nis_maps) }
    'boolean': { $use_nis_maps_bool = $use_nis_maps }
    default:   { fail('autofs::use_nis_maps is not a boolean.') }
  }

  case type3x($maps_hiera_merge) {
    'string':  { $maps_hiera_merge_bool = str2bool($maps_hiera_merge) }
    'boolean': { $maps_hiera_merge_bool = $maps_hiera_merge }
    default:   { fail('autofs::maps_hiera_merge is not a boolean.') }
  }

  case type3x($use_dash_hosts_for_net) {
    'string':  { $use_dash_hosts_for_net_bool = str2bool($use_dash_hosts_for_net) }
    'boolean': { $use_dash_hosts_for_net_bool = $use_dash_hosts_for_net }
    default:   { fail('autofs::use_dash_hosts_for_net is not a boolean.') }
  }

  case type3x($service_enable) {
    'string':  { $service_enable_bool = str2bool($service_enable) }
    'boolean': { $service_enable_bool = $service_enable }
    default:   { fail('autofs::service_enable is not a boolean.') }
  }

  case $maps_hiera_merge_bool {
    true:    { $maps_real = hiera_hash('autofs::maps', {}) }
    default: { $maps_real = $maps }
  }

  # variable validations
  if is_string($browse_mode)         == false { fail('autofs::browse_mode is not a string.') }
  if is_string($append_options)      == false { fail('autofs::append_options is not a string.') }
  if is_string($autofs_package_real) == false { fail('autofs::autofs_package is not a string.') }
  if is_string($autofs_service)      == false { fail('autofs::autofs_service is not a string.') }
  if is_string($nis_master_name)     == false { fail('autofs::nis_master_name is not a string.') }
  if is_hash($maps)                  == false { fail('autofs::maps is not a hash.') }

  validate_re($service_ensure, '^(running|stopped)$', "service_ensure must be running or stopped, got ${service_ensure}")
  validate_re($logging, '^(none|verbose|debug)$', "service_ensure must be none, verbose or debug, got ${service_ensure}")

  validate_absolute_path(
    $autofs_sysconfig_real,
    $autofs_auto_master_real,
  )

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
    content => template('autofs/auto_master.erb'),
    require => Package['autofs'],
  }

  create_resources('autofs::map', $maps_real)

  service { 'autofs':
    ensure    => $service_ensure,
    name      => $autofs_service,
    enable    => $service_enable_bool,
    require   => Package['autofs'],
    subscribe => [
      File['autofs_sysconfig'],
      File['auto.master'],
    ],
  }
}
