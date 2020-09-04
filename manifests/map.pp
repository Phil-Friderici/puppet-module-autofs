# == Define: autofs::map
#
# Manage autofs maps
#
define autofs::map (
  $mounts     = [],
  $file       = undef,
  # $autofs::maps which gets passed here, is also used for auto.master template.
  # The following parameters are not used in the mountmap.erb template.
  # But they need to exist to avoid "invalid parameter options" errors.
  $mountpoint = undef,
  $maptype    = undef,
  $manage     = true,
  $options    = undef,
) {

  $mnt = $name

  # variable preparations and validations
  case type3x($mounts) {
    'array':  { $mounts_array = $mounts }
    'string': { $mounts_array = [ $mounts ] }
    default:  { fail('autofs::map::mounts is not an array.') }
  }

  if is_string($file) == false { fail('autofs::map::file is not a string.') }

  # functionality
  $content = $file ? {
    undef   => template('autofs/mountmap.erb'),
    default => undef,
  }

  file { "mountmap_${mnt}":
    ensure  => file,
    path    => "/etc/auto.${mnt}",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => $file,
    content => $content,
  }

  # maptype is not used on Solaris
  case $osfamily {
    'Solaris': { $maptype_real = '' }
    default:   { $maptype_real = " ${maptype}"   }
  }

  case $options {
    undef:   { $options_real = '' }
    default: { $options_real = " ${options}" }
  }

  # build string for map, considering if maptype and format are set
  if $mountpoint {
    if $maptype {
      $mount = "/${mountpoint}${maptype_real} ${name}${options_real}"
    }
    elsif $manage == false {
      $mount = "/${mountpoint} -null${options_real}"
    }
    else {
      $mount = "/${mountpoint} /etc/auto.${name}${options_real}"
    }
  }
  else {
    $mount = "/${name} /etc/auto.${name}${options_real}"
  }

  concat::fragment { "auto.master2_${name}":
    target  => '/etc/auto.master2',
    content => "${mount}\n",
    order   => '10',
  }

}
