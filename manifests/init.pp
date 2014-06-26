class clamauditor ($scanpath, $smtpserver, $emails, $fromemail, $path = "/root/"){
  file { "${path}detect":
    ensure => 'directory',
    recurse => 'true',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }
  file { "${path}detect/banished":
    require => file["${path}detect"],
    ensure => 'directory',
    recurse => 'true',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }
  file { "${path}detect/auditor.rb":
    content => template('auditor/auditor.rb.erb'),
    mode => 755,
    require => file["${path}detect"]
  }
  file { "${path}detect/auditlib.rb":
    content => template('auditor/auditlib.rb.erb'),
    mode => 644,
    require => file["${path}detect"]
  }
  file { '/etc/watchlist.conf':
    content => template('auditor/watchlist.conf.erb'),
    mode => 644,
    require => [file["${path}detect/auditor.rb"], file["${path}detect/auditlib.rb"]]
  }
  package { 'sys-proctable':
    ensure   => 'installed',
    provider => 'gem',
  }
  package { 'daemons':
    ensure   => 'installed',
    provider => 'gem',
  }
  file { "${path}detect/scan.rb":
    mode => '0755',
    require => [file["${path}detect"],file["${path}detect/banished"],package['sys-proctable']],
    content => template('auditor/scan.rb.erb'),
  }
  exec { "run auditor":
    command => "${path}detect/auditor.rb start",
    onlyif => "test ! -f ${path}detect/auditlib.rb.pid",
    require => [file['/etc/watchlist.conf'],package['daemons']]
  }
  cron { auditor:
    command => "${path}detect/auditor.rb start",
    require => exec['run auditor'],
    user => "root",
    special => "reboot",
  }
  cron { clamscan:
    command => "${path}detect/scan.rb",
    require => file["${path}detect/scan.rb"],
    user    => root,
    minute => '10',
  }
  cron { freshclam:
    command => "/usr/bin/freshclam >/dev/null 2>&1",
    user    => root,
    hour    => 6,
  }
}
