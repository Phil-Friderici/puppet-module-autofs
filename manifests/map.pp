# == Define: autofs::map
#
# Manage autofs maps
#
define autofs::map (
  $mounts     = [],
  $file       = undef,
  $mapname    = undef,
  $mappath    = undef,
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
  case $mapname {
    undef:   { $mapname_real = "mountmap_${name}" }
    default: { $mapname_real = $mapname }
  }

  case $mappath {
    undef:   { $mappath_real = "/etc/auto.${name}" }
    default: { $mappath_real = $mappath }
  }

  case type3x($mounts) {
    'array':  { $mounts_array = $mounts }
    'string': { $mounts_array = [ $mounts ] }
    default:  { fail('autofs::map::mounts is not an array.') }
  }

  if is_string($file)         == false { fail('autofs::map::file is not a string.') }
  if is_string($mapname_real) == false { fail('autofs::map::mapname is not a string.') }
  if is_absolute_path($mappath_real) == false { fail('autofs::map::mappath is not an absolute path.') }

  # functionality
  $content = $file ? {
    undef   => template('autofs/mountmap.erb'),
    default => undef,
  }

  file { $mapname_real:
    ensure  => file,
    path    => $mappath_real,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => $file,
    content => $content,
  }
}
