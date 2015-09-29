# == Class: winnetdrive
#
# Maps a network drive and set security policies (zone, file types inclusion list)
#
# === Parameters
#
# [*None*]
#
# === Examples
#
#  include winnetwork::proxy
#
# === Authors
#
# songan.bui@thomsonreuters.com
#
# === Comment
#
# 
#
class winnetdrive (
  $sd_host     = hiera('sd_host'),
  $sd_domain   = hiera('sd_domain'),
  $sd_path     = hiera('sd_path'),
  $sd_username = hiera('sd_username'),
  $sd_userpwd  = hiera('sd_userpwd')
) {
  case $::osfamily {
    'windows': {
      ## Add shared drive host to Windows zone security
      exec { 'add shared drive to zone security':
        path     => $::path,
        command  => template('winnetdrive/set_sd_zone_exception.ps1.erb'),
        unless   => template('winnetdrive/check_sd_zone_exception.ps1.erb'),
        provider => powershell,
      }

      ## Enable moderate risk files types inclusion (exe,bat,cmd)
      file { 'C:/Windows/System32/GroupPolicy/User':
        ensure             => directory,
        source             => 'puppet:///modules/winnetdrive/gpo/User',
        recurse            => remote,
        source_permissions => ignore,
      }
      ~>
      exec { 'GPupdate for inclusion list':
        command     => 'gpupdate /force',
        path        => $::path,
        refreshonly => true,
      }

      ## Mount the shared drive
      exec { 'win_mount_shared_drive':
        path    => $::path,
        command => "net.exe use ${$sd_path} /PERSISTENT:YES \\\\${sd_host}.${sd_domain}\\public ${sd_userpwd} /USER:${sd_username}",
        unless  => "cmd.exe /c \"if exist \\\\${sd_host}.${sd_domain}\\public (exit 0) else (exit 1)\"",
        require => [Exec['add shared drive to zone security'], Exec['GPupdate for inclusion list']],
      }
    }
    default: { fail("${::osfamily} is not a supported platform.") }
  }
}