puppet-module-autofs
====================

Puppet module to manage autofs. Documentation TBD.

[![Build Status](https://api.travis-ci.org/kodguru/puppet-module-autofs.png)](https://travis-ci.org/kodguru/puppet-module-autofs)


# Compatibility
---------------
This module has been tested to work on the following systems with the latest
Puppet v3, v3 with future parser, v4, v5 and v6. See `.travis.yml` for the
exact matrix of supported Puppet and ruby versions.

* EL 5
* EL 6
* EL 7
* SLED / SLES 10
* SLED / SLES 11
* SLED / SLES 12
* Ubuntu 12.04 LTS
* Ubuntu 14.04 LTS

# Parameters
------------
---
#### browse_mode (type: String)
Set this to `YES` if you want your mounts to be browseable.

- Default: **'NO'**

---
#### timeout (type: Integer)
Default mount timeout.

- Default: **600**

---
#### negative_timeout (type: Integer)
Default negative timeout for failed mount attempts.

- Default: **60**

---
#### mount_wait (type: Integer)
Time to wait for a response from mount.

- Default: **-1**

---
#### umount_wait (type: Integer)
Time to wait for a response from umount.

- Default: **12**

---
#### mount_nfs_default_protocol (type: Integer)
Default protocol version used by mount.nfs

- Default: **4**

---
#### append_options (type: String)
Specify whether options should be appended to global options or replacing them.

- Default: **'yes'**

---
#### logging (type: String)
Set default log level `none`, `verbose` or `debug`.

- Default: **'none'**

---
#### maps (type: Hash)
Specify the maps managed. This value is sent to define `autofs::map`.

- Default: **{}**

---
#### maps_hiera_merge (type: Boolean)
If the module should merge `$maps` from different levels in hiera.

- Default: **false**

---
#### autofs_package (type: String)
Package name for autofs. Unset, this parameter will choose the appropriate default for the system.

- Default: **undef**

---
#### autofs_sysconfig (type: String)
Absolute path for autofs sysconfig location. Unset, this parameter will choose the appropriate default for the system.

- Default: **undef**

---
#### autofs_service (type: String)
Service name for autofs to manage.

- Default: **'autofs'**

---
#### autofs_auto_master (type: String)
Absolute path for autofs.master location. Unset, this parameter will choose the appropriate default for the system.

- Default: **undef**

---
#### use_nis_maps (type: Boolean)
If the module should load mount maps from NIS.

- Default: **true**

---
#### nis_master_name (type: String)
The name of the NIS map containing the auto.master data.

- Default: **'auto.master'**

---
#### service_ensure (type: String)
Value for the service ensure attribute. Valid values are `running` and `stopped`.

- Default: **'running'**

---
#### service_enable (type: Boolean)
Value for the service enable attribute.

- Default: **true**

---
#### use_dash_hosts_for_net (type: Boolean)
Set this to true makes autofs use `-hosts` for the /net mountpoint. Set to false to use `/etc/auto.net`.

- Default: **true**

---
## autofs::map parameters
---
#### mountpoint (type: String)
Specify the mountpoint in `auto.master`.

- Default: **undef**

---
#### maptype (type: String)
Specify maptype for mountpoint in `auto.master`.

- Default: **undef**

---
#### mapname (type: String)
The name for the map in `auto.master`. The default of `undef` will use the name of the key used to specify the mount.

- Default: **undef**

---
#### mappath (type: String)
Absolute path of the map file to be created and used in `auto.master`. The default of `undef` will use the name of the key used to specify the mount with `/etc/auto.` as prefix.

- Default: **undef**

---

#### mounts (type: Array)
Specify the mounts to be mounted at mountpoint as an array.

- Default: **[]**

---
#### manage (type: Boolean)
Boolean to manage mounts in `auto.master`. Setting it to false will result in `-null` in `auto.master`.

- Default: **true**

---
#### file (type: String)
Specify the mounts to be mounted at mountpoint from a file.

- Default: **undef**

---
#### options (type: String)
Specify extra mount points for this mountpoint in `auto.master`.

- *Default*: undef

---
# Examples

Manage `/home` with mounts from a file on Puppet fileserver:

    autofs::maps:
      home:
        mountpoint: 'home'
        file: 'puppet:///files/autofs/auto.home'

Results in `auto.master` with the following content.

    /home /etc/auto.home

Manage `/home` with mounts defined hiera:

    autofs::maps:
      home:
        mountpoint: 'home'
        mounts:
          - 'user1      nfsserver:/path/to/home/user1'
          - 'user2      nfsserver:/path/to/home/user2'

Results in `auto.home` with the following content and `auto.master` remaining as above.

    user1      nfsserver:/path/to/home/user1
    user2      nfsserver:/path/to/home/user2


Prevent `/home` from being managed by autofs (NIS included):

    autofs::maps:
      home:
          mountpoint: 'home'
          manage: false

Result in auto.master:

    /home -null
