class opencontrail_ci::nexus_repository(
  $registry_ports = [5000],
) {
  include '::gnupg'

  gnupg_key { 'obs:woid:nexus3':
    ensure     => present,
    key_id     => 'a6f34cb3',
    user       => 'root',
    key_source => 'puppet:///modules/opencontrail_ci/nexus3_gpg.pub',
    key_type   => 'public',
  }

  yumrepo {'obs:woid:nexus3':
    baseurl  => 'http://download.opensuse.org/repositories/home:/woid:/nexus3/CentOS_7/',
    descr    => 'Nexus3 subrepository (CentOS_7)',
    enabled  => true,
    gpgcheck => true,
    gpgkey   => 'http://download.opensuse.org/repositories/home:/woid:/nexus3/CentOS_7/repodata/repomd.xml.key',
  }

  package {'nexus3':
    ensure  => '3.13.0.01-17.1',
    require => [
      Gnupg_key['obs:woid:nexus3'],
      Yumrepo['obs:woid:nexus3'],
    ]
  }

  service {'nexus3':
    ensure    => running,
    enable    => true,
    subscribe => Package['nexus3'],
  }

  # Setup reverse proxy
  include '::nginx'

  nginx::resource::server { $::fqdn:
      listen_port       => 80,
      proxy             => 'http://localhost:8081',
      server_cfg_append => {
        'client_max_body_size' => '1G',
      },
  }

  selboolean {'httpd_can_network_connect':
    persistent => true,
    value      => on,
  }

  firewall {'100 accept all HTTP(s)':
    proto  => tcp,
    dport  => [80, 443],
    action => accept,
  }

  firewall {'101 accept ports for nexus docker registries':
    proto  => tcp,
    dport  => $registry_ports,
    action => accept,
  }
}
