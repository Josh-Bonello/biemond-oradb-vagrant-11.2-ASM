node 'dbasm.example.com' {
  include oradb_asm_os
  include nfs
  include oradb_asm
}

Package{allow_virtual => false,}

# operating settings for Database & Middleware
class oradb_asm_os {

  class { 'swap_file':
    swapfile     => '/var/swap.1',
    swapfilesize => '8192000000'
  }

  # set the tmpfs
  mount { '/dev/shm':
    ensure      => present,
    atboot      => true,
    device      => 'tmpfs',
    fstype      => 'tmpfs',
    options     => 'size=2000m',
  }

  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  $all_groups = ['oinstall','dba' ,'oper','asmdba','asmadmin','asmoper']

  group { $all_groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    uid         => 500,
    gid         => 'oinstall',
    groups      => ['oinstall','dba','oper','asmdba'],
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/oracle',
    comment     => 'This user oracle was created by Puppet',
    require     => Group[$all_groups],
    managehome  => true,
  }

  user { 'grid' :
    ensure      => present,
    uid         => 501,
    gid         => 'oinstall',
    groups      => ['oinstall','dba','asmadmin','asmdba','asmoper'],
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/grid',
    comment     => 'This user grid was created by Puppet',
    require     => Group[$all_groups],
    managehome  => true,
  }


  $install = ['binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64',
              'ksh.x86_64','libaio.x86_64',
              'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64',
              'compat-libcap1.x86_64', 'gcc.x86_64',
              'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64',
              'libstdc++-devel.x86_64',
              'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64',
              'libXtst.x86_64','xorg-x11-xauth.x86_64',
              'elfutils-libelf-devel','kernel-debug']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
                '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '10240'  ,},},
                'grid'    => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '10240'  ,},},
                },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class nfs {
  require oradb_asm_os

  file { '/home/nfs_server_data':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmadmin',
    require =>  User['grid'],
  }

  class { 'nfs::server':
    package => latest,
    service => running,
    enable  => true,
  }

  nfs::export { '/home/nfs_server_data':
    options => [ 'rw', 'sync', 'no_wdelay','insecure_locks','no_root_squash' ],
    clients => [ '*' ],
    require => [File['/home/nfs_server_data'],Class['nfs::server'],],
  }

  file { '/nfs_client':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmadmin',
    require =>  User['grid'],
  }

  mounts { 'Mount point for NFS data':
    ensure  => present,
    source  => 'dbasm:/home/nfs_server_data',
    dest    => '/nfs_client',
    type    => 'nfs',
    opts    => 'rw,bg,hard,nointr,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0  0 0',
    require => [File['/nfs_client'],Nfs::Export['/home/nfs_server_data'],]
  }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b1',
    require   => Mounts['Mount point for NFS data'],
  }
  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b2',
    require   => [Mounts['Mount point for NFS data'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520']],
  }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b3 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b3',
    require   => [Mounts['Mount point for NFS data'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520'],],
  }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b4 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b4',
    require   => [Mounts['Mount point for NFS data'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b3 bs=1M count=7520'],],
  }

  $nfs_files = ['/nfs_client/asm_sda_nfs_b1','/nfs_client/asm_sda_nfs_b2','/nfs_client/asm_sda_nfs_b3','/nfs_client/asm_sda_nfs_b4']

  file { $nfs_files:
    ensure  => present,
    owner   => 'grid',
    group   => 'asmadmin',
    mode    => '0664',
    require => Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b4 bs=1M count=7520'],
  }
}

class oradb_asm {
  require oradb_asm_os,nfs

    oradb::installasm{ 'db_linux-x64':
      version                => hiera('db_version'),
      file                   => hiera('asm_file'),
      grid_type              => 'HA_CONFIG',
      grid_base              => hiera('grid_base_dir'),
      grid_home              => hiera('grid_home_dir'),
      ora_inventory_dir      => hiera('oraInventory_dir'),
      user_base_dir          => '/home',
      user                   => hiera('grid_os_user'),
      group                  => 'asmdba',
      group_install          => 'oinstall',
      group_oper             => 'asmoper',
      group_asm              => 'asmadmin',
      sys_asm_password       => 'Welcome01',
      asm_monitor_password   => 'Welcome01',
      asm_diskgroup          => 'DATA',
      disk_discovery_string  => '/nfs_client/asm*',
      disks                  => '/nfs_client/asm_sda_nfs_b1,/nfs_client/asm_sda_nfs_b2',
      disk_redundancy        => 'EXTERNAL',
      download_dir           => hiera('oracle_download_dir'),
      remote_file            => false,
      puppet_download_mnt_point => hiera('oracle_source'),
    }

    oradb::opatchupgrade{'112000_opatch_upgrade_asm':
      oracle_home             => hiera('grid_home_dir'),
      patch_file              => 'p6880880_112000_Linux-x86-64.zip',
      csi_number              => undef,
      support_id              => undef,
      opversion              => '11.2.0.3.6',
      user                   => hiera('grid_os_user'),
      group                  => 'oinstall',
      download_dir            => hiera('oracle_download_dir'),
      puppet_download_mnt_point => hiera('oracle_source'),
      require                => Oradb::Installasm['db_linux-x64'],
    }

    oradb::opatch{'19791420_grid_patch':
      ensure                 => 'present',
      oracle_product_home      => hiera('grid_home_dir'),
      patch_id                => '19791420',
      patch_file              => 'p19791420_112040_Linux-x86-64.zip',
      clusterware            => true,
      bundle_sub_patch_id       => '19121552', # sub patch_id of bundle patch ( else I can't detect it)
      bundle_sub_folder        => '19380115', # optional subfolder inside the patch zip
      user                   => hiera('grid_os_user'),
      group                  => 'oinstall',
      download_dir            => hiera('oracle_download_dir'),
      ocmrf                  => true,
      require                => Oradb::Opatchupgrade['112000_opatch_upgrade_asm'],
      puppet_download_mnt_point => hiera('oracle_source'),
    }

    oradb::installdb{ 'db_linux-x64':
      version                => hiera('db_version'),
      file                   => hiera('db_file'),
      database_type          => 'EE',
      ora_inventory_dir      => hiera('oraInventory_dir'),
      oracle_base            => hiera('oracle_base_dir'),
      oracle_home            => hiera('oracle_home_dir'),
      user_base_dir          => '/home',
      user                   => hiera('oracle_os_user'),
      group                  => 'dba',
      group_install          => 'oinstall',
      group_oper             => 'oper',
      download_dir           => hiera('oracle_download_dir'),
      remote_file            => false,
      puppet_download_mnt_point => hiera('oracle_source'),
      require                => Oradb::Opatch['19791420_grid_patch'],
    }

    oradb::opatchupgrade{'112000_opatch_upgrade_db':
      oracle_home             => hiera('oracle_home_dir'),
      patch_file              => 'p6880880_112000_Linux-x86-64.zip',
      csi_number              => undef,
      support_id              => undef,
      opversion               => '11.2.0.3.6',
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      download_dir            => hiera('oracle_download_dir'),
      puppet_download_mnt_point => hiera('oracle_source'),
      require                 => Oradb::Installdb['db_linux-x64'],
    }

    oradb::opatch{'19791420_db_patch':
      ensure                   => 'present',
      oracle_product_home      => hiera('oracle_home_dir'),
      patch_id                 => '19791420',
      patch_file               => 'p19791420_112040_Linux-x86-64.zip',
      clusterware              => true,
      bundle_sub_patch_id      => '19121551', #,'19121552', # sub patch_id of bundle patch ( else I can't detect it)
      bundle_sub_folder        => '19380115', # optional subfolder inside the patch zip
      user                     => hiera('oracle_os_user'),
      group                    => 'oinstall',
      download_dir             => hiera('oracle_download_dir'),
      ocmrf                    => true,
      require                  => Oradb::Opatchupgrade['112000_opatch_upgrade_db'],
      puppet_download_mnt_point => hiera('oracle_source'),
    }

    oradb::opatch{'19791420_db_patch_2':
      ensure                  => 'present',
      oracle_product_home     => hiera('oracle_home_dir'),
      patch_id                => '19791420',
      patch_file              => 'p19791420_112040_Linux-x86-64.zip',
      clusterware             => false,
      bundle_sub_patch_id     => '19282021', # sub patch_id of bundle patch ( else I can't detect it)
      bundle_sub_folder       => '19282021', # optional subfolder inside the patch zip
      user                    => hiera('oracle_os_user'),
      group                   => 'oinstall',
      download_dir            => hiera('oracle_download_dir'),
      ocmrf                   => true,
      require                 => Oradb::Opatch['19791420_db_patch'],
      puppet_download_mnt_point => hiera('oracle_source'),
    }

    ora_asm_diskgroup{ 'RECO@+ASM':
      ensure          => 'present',
      au_size         => '1',
      compat_asm      => '11.2.0.0.0',
      compat_rdbms    => '10.1.0.0.0',
      diskgroup_state => 'MOUNTED',
      disks           => {'RECO_0000' => {'diskname' => 'RECO_0000', 'path' => '/nfs_client/asm_sda_nfs_b3'},
                          'RECO_0001' => {'diskname' => 'RECO_0001', 'path' => '/nfs_client/asm_sda_nfs_b4'}},
      redundancy_type => 'EXTERNAL',
      require         => Oradb::Opatch['19791420_db_patch_2'],
    }

    oradb::database{ 'oraDb':
      oracle_base              => hiera('oracle_base_dir'),
      oracle_home              => hiera('oracle_home_dir'),
      version                  => hiera('dbinstance_version'),
      user                     => hiera('oracle_os_user'),
      group                    => hiera('oracle_os_group'),
      download_dir             => hiera('oracle_download_dir'),
      action                   => 'create',
      db_name                  => hiera('oracle_database_name'),
      db_domain                => hiera('oracle_database_domain_name'),
      sys_password             => hiera('oracle_database_sys_password'),
      system_password          => hiera('oracle_database_system_password'),
      # template                => 'my_dbtemplate_11gR2_asm',
      # puppet_download_mnt_point  => '/vagrant',
      template                 => 'dbtemplate_11gR2_asm',
      character_set            => 'AL32UTF8',
      nationalcharacter_set    => 'UTF8',
      sample_schema            => 'FALSE',
      memory_percentage        => '40',
      memory_total             => '800',
      database_type            => 'MULTIPURPOSE',
      em_configuration         => 'NONE',
      storage_type             => 'ASM',
      asm_snmp_password        => 'Welcome01',
      asm_diskgroup            => 'DATA',
      recovery_diskgroup       => 'RECO',
      recovery_area_destination => 'RECO',
      require                   => [Oradb::Opatch['19791420_db_patch_2'],
                                    Ora_asm_diskgroup['RECO@+ASM'],],
    }

    oradb::dbactions{ 'start oraDb':
      oracle_home             => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      action                  => 'start',
      db_name                 => hiera('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracle_home             => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      db_name                 => hiera('oracle_database_name'),
      require                 => Oradb::Dbactions['start oraDb'],
    }

}

