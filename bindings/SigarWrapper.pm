#extension source generator for all bindings
package SigarWrapper;

use strict;
use Config;
use Cwd;
use Exporter;
use File::Path;
use IO::File ();

our @ISA = qw(Exporter);
our @EXPORT = qw(generate);

sub archname {
    my $os = lc $^O;
    my $vers = $Config{osvers};
    my $arch = $Config{archname};

    if ($os =~ /win32/) {
        return 'x86-winnt';
    }
    elsif ($os =~ /linux/) {
	if ($arch =~ /_64/) {
	    return 'amd64-linux';
	}
	else {
	    return 'x86-linux';
	}
    }
    elsif ($os =~ /hpux/) {
        if ($vers =~ /11\./) {
            return 'pa-hpux-11';
        }
    }
    elsif ($os =~ /aix/) {
        return 'ppc-aix-5';
    }
    elsif ($os =~ /solaris/) {
        if ($arch =~ /sun4/) {
            return 'sparc-solaris';
        }
        elsif ($arch =~ /.86/) {
            return 'x86-solaris';
        }
    }
    elsif ($os =~ /darwin/) {
        return 'universal-macosx';
    }
    elsif ($os =~ /freebsd/) { 
        if($arch =~ /.86/) { 
            if($vers =~ /6\../ ) { 
                return 'x86-freebsd-6'; 
            }
        } 
        elsif( $arch =~ /amd64/) { 
            if($vers =~ /6\../ ) { 
                return 'amd64-freebsd-6'; 
            } 
        } 
    } 

    return '';
}

my %platforms = (
    A => "AIX",
    D => "Darwin",
    F => "FreeBSD",
    H => "HPUX",
    L => "Linux",
    S => "Solaris",
    W => "Win32",
);

my %has_name_arg = map { $_, 1 } qw(FileSystemUsage FileAttrs DirStat DirUsage
                                    NetInterfaceConfig NetInterfaceStat);

my %proc_no_arg = map { $_, 1 } qw(stat);

my %get_not_impl = map { $_, 1 } qw(net_address net_route net_connection net_stat
                                    who cpu_info file_system); #list funcs only

sub supported_platforms {
    my $p = shift;
    return 'Undocumented' unless $p;
    if ($p eq '*') {
        return 'All';
    }

    my @platforms;
    for (split //, $p) {
        push @platforms, $platforms{$_};
    }

    return join ", ", @platforms;
}

sub hash {
    return unpack("%32C*", shift) % 65535;
}

my $nfs_v2 = [
   {
      name => 'getattr', type => 'Long',
   },
   {
      name => 'setattr', type => 'Long',
   },
   {
      name => 'root', type => 'Long',
   },
   {
      name => 'lookup', type => 'Long',
   },
   {
      name => 'readlink', type => 'Long',
   },
   {
      name => 'read', type => 'Long',
   },
   {
      name => 'writecache', type => 'Long',
   },
   {
      name => 'write', type => 'Long',
   },
   {
      name => 'create', type => 'Long',
   },
   {
      name => 'remove', type => 'Long',
   },
   {
      name => 'rename', type => 'Long',
   },
   {
      name => 'link', type => 'Long',
   },
   {
      name => 'symlink', type => 'Long',
   },
   {
      name => 'mkdir', type => 'Long',
   },
   {
      name => 'rmdir', type => 'Long',
   },
   {
      name => 'readdir', type => 'Long',
   },
   {
      name => 'fsstat', type => 'Long',
   },
];

my $nfs_v3 = [
   {
      name => 'getattr', type => 'Long',
   },
   {
      name => 'setattr', type => 'Long',
   },
   {
      name => 'lookup', type => 'Long',
   },
   {
      name => 'access', type => 'Long',
   },
   {
      name => 'readlink', type => 'Long',
   },
   {
      name => 'read', type => 'Long',
   },
   {
      name => 'write', type => 'Long',
   },
   {
      name => 'create', type => 'Long',
   },
   {
      name => 'mkdir', type => 'Long',
   },
   {
      name => 'symlink', type => 'Long',
   },
   {
      name => 'mknod', type => 'Long',
   },
   {
      name => 'remove', type => 'Long',
   },
   {
      name => 'rmdir', type => 'Long',
   },
   {
      name => 'rename', type => 'Long',
   },
   {
      name => 'link', type => 'Long',
   },
   {
      name => 'readdir', type => 'Long',
   },
   {
      name => 'readdirplus', type => 'Long',
   },
   {
      name => 'fsstat', type => 'Long',
   },
   {
      name => 'fsinfo', type => 'Long',
   },
   {
      name => 'pathconf', type => 'Long',
   },
   {
      name => 'commit', type => 'Long',
   },
];

our %classes = (
    Mem => [
      {
         name => 'total', type => 'Long',
         desc => 'Total system memory',
         plat => '*',
         cmd  => {
             AIX => 'lsattr -El sys0 -a realmem',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => '',
             Win32   => 'taskman',
         },
      },
      {
         name => 'ram', type => 'Long',
         desc => 'System Random Access Memory (in MB)',
         plat => '*',
         cmd  => {
             AIX     => 'lsattr -El sys0 -a realmem',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'cat /proc/mtrr | head -1',
             Solaris => '',
             Win32   => '',
         },
      },
      {
         name => 'used', type => 'Long',
         desc => 'Total used system memory',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => '',
             Win32   => 'taskman',
         },
      },
      {
         name => 'free', type => 'Long',
         desc => 'Total free system memory (e.g. Linux plus cached)',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => '',
             Win32   => 'taskman',
         },
      },
      {
         name => 'actual_used', type => 'Long',
         desc => 'Actual total used system memory (e.g. Linux minus buffers)',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => '',
             Win32   => 'taskman',
         },
      },
      {
         name => 'actual_free', type => 'Long',
         desc => 'Actual total free system memory',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => '',
             Win32   => 'taskman',
         },
      },
    ],
    Swap => [
      {
         name => 'total', type => 'Long',
         desc => 'Total system swap',
         plat => '*',
         cmd  => {
             AIX     => 'lsps -s',
             Darwin  => 'sysctl vm.swapusage',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => 'swap -s',
             Win32   => '',
         },
      },
      {
         name => 'used', type => 'Long',
         desc => 'Total used system swap',
         plat => '*',
         cmd  => {
             AIX     => 'lsps -s',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => 'swap -s',
             Win32   => '',
         },
      },
      {
         name => 'free', type => 'Long',
         desc => 'Total free system swap',
         plat => '*',
         cmd  => {
             AIX => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'free',
             Solaris => 'swap -s',
             Win32   => '',
         },
      },
      {
         name => 'page_in', type => 'Long',
         desc => 'Pages in',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'vmstat',
             Solaris => 'vmstat',
             Win32   => '',
         },
      },
      {
         name => 'page_out', type => 'Long',
         desc => 'Pages out',
         plat => '*',
         cmd  => {
             AIX     => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'vmstat',
             Solaris => 'vmstat',
             Win32   => '',
         },
      },
    ],
    Cpu => [
      {
         name => 'user', type => 'Long',
         desc => 'Total system cpu user time',
         plat => '*'
      },
      {
         name => 'sys', type => 'Long',
         desc => 'Total system cpu kernel time',
         plat => '*'
      },
      {
         name => 'nice', type => 'Long',
         desc => 'Total system cpu nice time',
         plat => 'DFHL'
      },
      {
         name => 'idle', type => 'Long',
         desc => 'Total system cpu idle time',
         plat => '*'
      },
      {
         name => 'wait', type => 'Long',
         desc => 'Total system cpu io wait time',
         plat => 'ALHS'
      },
      {
         name => 'total', type => 'Long',
         desc => 'Total system cpu time',
         plat => '*'
      },
    ],
    CpuInfo => [
      {
         name => 'vendor', type => 'String',
         desc => 'CPU vendor id',
         plat => 'AFLHSW'
      },
      {
         name => 'model', type => 'String',
         desc => 'CPU model',
         plat => 'AFLHSW'
      },
      {
         name => 'mhz', type => 'Int',
         desc => 'CPU speed',
         plat => 'AFHLSW'
      },
      {
         name => 'cache_size', type => 'Long',
         desc => 'CPU cache size',
         plat => 'AL'
      },
    ],
    Uptime => [
      {
         name => 'uptime', type => 'Double',
         desc => 'Time since machine started in seconds',
         plat => '*'
      },
    ],
    ProcMem => [
      {
         name => 'size', type => 'Long',
         desc => 'Total process virtual memory',
         plat => '*'
      },
      {
         name => 'resident', type => 'Long',
         desc => 'Total process resident memory',
         plat => '*'
      },
      {
         name => 'share', type => 'Long',
         desc => 'Total process shared memory',
         plat => 'AHLS'
      },
      {
         name => 'minor_faults', type => 'Long',
         desc => 'non i/o page faults',
         plat => 'AHLS'
      },
      {
         name => 'major_faults', type => 'Long',
         desc => 'i/o page faults',
         plat => 'AHLS'
      },
      {
         name => 'page_faults', type => 'Long',
         desc => 'Total number of page faults',
         plat => 'ADHLSW'
      },
    ],
    ProcCred => [
      {
         name => 'uid', type => 'Long',
         desc => 'Process user id',
         plat => 'ADFHLS'
      },
      {
         name => 'gid', type => 'Long',
         desc => 'Process group id',
         plat => 'ADFHLS'
      },
      {
         name => 'euid', type => 'Long',
         desc => 'Process effective user id',
         plat => 'ADFHLS'
      },
      {
         name => 'egid', type => 'Long',
         desc => 'Process effective group id',
         plat => 'ADFHLS'
      },
    ],
    ProcCredName => [
      {
         name => 'user', type => 'String',
         desc => 'Process owner user name',
         plat => '*'
      },
      {
         name => 'group', type => 'String',
         desc => 'Process owner group name',
         plat => '*'
      },
    ],
    ProcTime => [
      {
         name => 'start_time', type => 'Long',
         desc => 'Time process was started in seconds',
         plat => '*'
      },
      {
         name => 'user', type => 'Long',
         desc => 'Process cpu user time',
         plat => '*'
      },
      {
         name => 'sys', type => 'Long',
         desc => 'Process cpu kernel time',
         plat => '*'
      },
      {
         name => 'total', type => 'Long',
         desc => 'Process cpu time (sum of User and Sys)',
         plat => '*'
      },
    ],
    ProcCpu => [
      {
         name => 'percent', type => 'Double',
         desc => 'Process cpu usage',
         plat => '*'
      },
      {
         name => 'last_time', type => 'Long',
         desc => '',
         plat => '*'
      },
    ],
    ProcState => [
      {
         name => 'state', type => 'Char',
         desc => 'Process state (Running, Zombie, etc.)',
         plat => '*'
      },
      {
         name => 'name', type => 'String',
         desc => 'Name of the process program',
         plat => '*'
      },
      {
         name => 'ppid', type => 'Long',
         desc => 'Process parent process id',
         plat => '*'
      },
      {
         name => 'tty', type => 'Int',
         desc => 'Device number of rocess controling terminal',
         plat => 'AHLS'
      },
      {
         name => 'nice', type => 'Int',
         desc => 'Nice value of process',
         plat => 'ADFHLS'
      },
      {
         name => 'priority', type => 'Int',
         desc => 'Kernel scheduling priority of process',
         plat => 'DFHLSW'
      },
      {
         name => 'threads', type => 'Long',
         desc => 'Number of active threads',
         plat => 'ADHLSW'
      },
      {
         name => 'processor', type => 'Int',
         desc => 'Processor number last run on',
         plat => 'AHLS'
      },
    ],
    ProcFd => [
      {
         name => 'total', type => 'Long',
         desc => 'Total number of open file descriptors',
         plat => 'AHLSW'
      },
    ],
    ProcStat => [
      {
         name => 'total', type => 'Long',
         desc => 'Total number of processes',
         plat => '*'
      },
      {
         name => 'idle', type => 'Long',
         desc => 'Total number of processes in idle state',
         plat => '*'
      },
      {
         name => 'running', type => 'Long',
         desc => 'Total number of processes in run state',
         plat => '*'
      },
      {
         name => 'sleeping', type => 'Long',
         desc => 'Total number of processes in sleep state',
         plat => '*'
      },
      {
         name => 'stopped', type => 'Long',
         desc => 'Total number of processes in stop state',
         plat => '*'
      },
      {
         name => 'zombie', type => 'Long',
         desc => 'Total number of processes in zombie state',
         plat => '*'
      },
    ],
    ProcExe => [
      {
         name => 'name', type => 'String',
         desc => 'Name of process executable',
         plat => 'FLSW',
         cmd  => {
             AIX => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'ls -l /proc/$$/exe',
             Solaris => '',
             Win32   => '',
         },
      },
      {
         name => 'cwd', type => 'String',
         desc => 'Name of process current working directory',
         plat => 'LSW',
         cmd  => {
             AIX => '',
             Darwin  => '',
             FreeBSD => '',
             HPUX    => '',
             Linux   => 'ls -l /proc/$$/cwd',
             Solaris => '',
             Win32   => '',
         },
      },
    ],
    ThreadCpu => [
      {
         name => 'user', type => 'Long',
         desc => 'Thread cpu user time',
         plat => 'AHLSW'
      },
      {
         name => 'sys', type => 'Long',
         desc => 'Thread cpu kernel time',
         plat => 'AHLSW'
      },
      {
         name => 'total', type => 'Long',
         desc => 'Thread cpu time (sum of User and Sys)',
         plat => 'AHLSW'
      },
    ],
    FileSystem => [
      {
         name => 'dir_name', type => 'String',
         desc => 'Directory name',
         plat => '*'
      },
      {
         name => 'dev_name', type => 'String',
         desc => 'Device name',
         plat => '*'
      },
      {
         name => 'type_name', type => 'String',
         desc => 'File system generic type name',
         plat => '*'
      },
      {
         name => 'sys_type_name', type => 'String',
         desc => 'File system os specific type name',
         plat => '*'
      },
      {
         name => 'type', type => 'Int',
         desc => 'File system type',
         plat => '*'
      },
      {
         name => 'flags', type => 'Long',
         desc => 'File system flags',
         plat => '*'
      },
    ],
    FileSystemUsage => [
      {
         name => 'total', type => 'Long',
         desc => 'Total bytes of filesystem',
         plat => '*'
      },
      {
         name => 'free', type => 'Long',
         desc => 'Total free bytes on filesystem',
         plat => '*'
      },
      {
         name => 'used', type => 'Long',
         desc => 'Total used bytes on filesystem',
         plat => '*'
      },
      {
         name => 'avail', type => 'Long',
         desc => 'Total free bytes on filesystem available to caller',
         plat => '*'
      },
      {
         name => 'files', type => 'Long',
         desc => 'Total number of file nodes on the filesystem',
         plat => 'ADFHLS'
      },
      {
         name => 'free_files', type => 'Long',
         desc => 'Number of free file nodes on the filesystem',
         plat => 'ADFHLS'
      },
      {
         name => 'disk_reads', type => 'Long',
         desc => 'Number of physical disk reads',
         plat => 'AFHLSW'
      },
      {
         name => 'disk_writes', type => 'Long',
         desc => 'Number of physical disk writes',
         plat => 'AFHLSW'
      },
      {
         name => 'disk_read_bytes', type => 'Long',
         desc => 'Number of physical disk bytes read',
         plat => ''
      },
      {
         name => 'disk_write_bytes', type => 'Long',
         desc => 'Number of physical disk bytes written',
         plat => ''
      },
      {
         name => 'disk_queue', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'use_percent', type => 'Double',
         desc => 'Percent of disk used',
         plat => '*'
      },
    ],
    FileAttrs => [
      {
         name => 'permissions', type => 'Long',
      },
      {
         name => 'type', type => 'Int',
      },
      {
         name => 'uid', type => 'Long',
      },
      {
         name => 'gid', type => 'Long',
      },
      {
         name => 'inode', type => 'Long',
      },
      {
         name => 'device', type => 'Long',
      },
      {
         name => 'nlink', type => 'Long',
      },
      {
         name => 'size', type => 'Long',
      },
      {
         name => 'atime', type => 'Long',
      },
      {
         name => 'ctime', type => 'Long',
      },
      {
         name => 'mtime', type => 'Long',
      },
    ],
    DirStat => [
      {
         name => 'total', type => 'Long',
      },
      {
         name => 'files', type => 'Long',
      },
      {
         name => 'subdirs', type => 'Long',
      },
      {
         name => 'symlinks', type => 'Long',
      },
      {
         name => 'chrdevs', type => 'Long',
      },
      {
         name => 'blkdevs', type => 'Long',
      },
      {
         name => 'sockets', type => 'Long',
      },
      {
         name => 'disk_usage', type => 'Long',
      },
    ],
    NetInfo => [
      {
         name => 'default_gateway', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'host_name', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'domain_name', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'primary_dns', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'secondary_dns', type => 'String',
         desc => '',
         plat => ''
      },
    ],
    NetRoute => [
      {
         name => 'destination', type => 'NetAddress',
         desc => '',
         plat => 'HLW'
      },
      {
         name => 'gateway', type => 'NetAddress',
         desc => '',
         plat => 'HLW'
      },
      {
         name => 'flags', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'refcnt', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'use', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'metric', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'mask', type => 'NetAddress',
         desc => '',
         plat => 'HL'
      },
      {
         name => 'mtu', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'window', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'irtt', type => 'Long',
         desc => '',
         plat => 'L'
      },
      {
         name => 'ifname', type => 'String',
         desc => '',
         plat => 'L'
      },
    ],
    NetInterfaceConfig => [
      {
         name => 'name', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'hwaddr', type => 'NetAddress',
         desc => '',
         plat => '*'
      },
      {
         name => 'type', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'description', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'address', type => 'NetAddress',
         desc => '',
         plat => '*'
      },
      {
         name => 'destination', type => 'NetAddress',
         desc => '',
         plat => '*'
      },
      {
         name => 'broadcast', type => 'NetAddress',
         desc => '',
         plat => '*'
      },
      {
         name => 'netmask', type => 'NetAddress',
         desc => '',
         plat => '*'
      },
      {
         name => 'flags', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'mtu', type => 'Long',
         desc => '',
         plat => 'DFL'
      },
      {
         name => 'metric', type => 'Long',
         desc => '',
         plat => 'DFL'
      },
    ],
    NetInterfaceStat => [
      {
         name => 'rx_bytes', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'rx_packets', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'rx_errors', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'rx_dropped', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'rx_overruns', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'rx_frame', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'tx_bytes', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'tx_packets', type => 'Long',
         desc => '',
         plat => '*'
      },
      {
         name => 'tx_errors', type => 'Long',
         desc => '*',
         plat => ''
      },
      {
         name => 'tx_dropped', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'tx_overruns', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'tx_collisions', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'tx_carrier', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'speed', type => 'Long',
         desc => '',
         plat => ''
      },
    ],
    NetConnection => [
      {
         name => 'local_port', type => 'Long',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'local_address', type => 'NetAddress',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'remote_port', type => 'Long',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'remote_address', type => 'NetAddress',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'type', type => 'Int',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'state', type => 'Int',
         desc => '',
         plat => 'LFSW'
      },
      {
         name => 'send_queue', type => 'Long',
         desc => '',
         plat => 'LFS'
      },
      {
         name => 'receive_queue', type => 'Long',
         desc => '',
         plat => 'LFS'
      },
    ],
    #only for jfieldId cache/setters
    NetStat => [
      {
         name => 'tcp_inbound_total', type => 'Int',
      },
      {
         name => 'tcp_outbound_total', type => 'Int',
      },
      {
         name => 'all_inbound_total', type => 'Int',
      },
      {
         name => 'all_outbound_total', type => 'Int',
      },
    ],
    Tcp => [
      {
         name => 'active_opens', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'passive_opens', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'attempt_fails', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'estab_resets', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'curr_estab', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'in_segs', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'out_segs', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'retrans_segs', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'in_errs', type => 'Long',
         desc => '',
         plat => ''
      },
      {
         name => 'out_rsts', type => 'Long',
         desc => '',
         plat => ''
      },
    ],
    NfsClientV2 => $nfs_v2,
    NfsServerV2 => $nfs_v2,
    NfsClientV3 => $nfs_v3,
    NfsServerV3 => $nfs_v3,
    ResourceLimit => [
      {
         name => 'cpu_cur',
      },
      {
         name => 'cpu_max',
      },
      {
         name => 'file_size_cur',
      },
      {
         name => 'file_size_max',
      },
      {
         name => 'pipe_size_max',
      },
      {
         name => 'pipe_size_cur',
      },
      {
         name => 'data_cur',
      },
      {
         name => 'data_max',
      },
      {
         name => 'stack_cur',
      },
      {
         name => 'stack_max',
      },
      {
         name => 'core_cur',
      },
      {
         name => 'core_max',
      },
      {
         name => 'memory_cur',
      },
      {
         name => 'memory_max',
      },
      {
         name => 'processes_cur',
      },
      {
         name => 'processes_max',
      },
      {
         name => 'open_files_cur',
      },
      {
         name => 'open_files_max',
      },
      {
         name => 'virtual_memory_cur',
      },
      {
         name => 'virtual_memory_max',
      },
    ],
    SysInfo => [
      {
         name => 'name', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'version', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'arch', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'machine', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'description', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'patch_level', type => 'String',
         desc => '',
         plat => 'W'
      },
      {
         name => 'vendor', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'vendor_version', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'vendor_name', type => 'String',
         desc => '',
         plat => '*'
      },
      {
         name => 'vendor_code_name', type => 'String',
         desc => '',
         plat => '*'
      },
    ],
    Who => [
      {
         name => 'user', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'device', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'host', type => 'String',
         desc => '',
         plat => ''
      },
      {
         name => 'time', type => 'Long',
         desc => '',
         plat => ''
      },
    ],
);

$classes{DirUsage} = $classes{DirStat};

my(%extends) = (
    ProcCpu => 'ProcTime',
);

while (my($subclass, $superclass) = each %extends) {
    push @{ $classes{$subclass} }, @{ $classes{$superclass} };
}

our %cmds = (
    Mem => {
       AIX     => 'top',
       Darwin  => 'top',
       FreeBSD => 'top',
       HPUX    => 'top',
       Linux   => 'top',
       Solaris => 'top',
       Win32   => 'taskman',
    },
    Swap => {
       AIX     => 'top',
       Darwin  => 'top',
       FreeBSD => 'top',
       HPUX    => 'top',
       Linux   => 'top',
       Solaris => 'top',
       Win32   => 'taskman',
    },
    Cpu => {
       AIX     => 'top',
       Darwin  => 'top',
       FreeBSD => 'top',
       HPUX    => 'top',
       Linux   => 'top',
       Solaris => 'top',
       Win32   => 'taskman',
    },
    CpuInfo => {
       AIX     => 'lsattr -El proc0',
       Darwin  => '',
       FreeBSD => '',
       HPUX    => '',
       Linux   => 'cat /proc/cpuinfo',
       Solaris => 'psrinfo -v',
       Win32   => '',
    },
    Uptime => {
       AIX     => 'uptime',
       Darwin  => 'uptime',
       FreeBSD => 'uptime',
       HPUX    => 'uptime',
       Linux   => 'uptime',
       Solaris => 'uptime',
       Win32   => '',
    },
    ProcMem => {
       AIX     => 'top, ps',
       Darwin  => 'top, ps',
       FreeBSD => 'top, ps',
       HPUX    => 'top, ps',
       Linux   => 'top, ps',
       Solaris => 'top, ps',
       Win32   => 'taskman',
    },
    ProcCred => {
       AIX     => 'top, ps',
       Darwin  => 'top, ps',
       FreeBSD => 'top, ps',
       HPUX    => 'top, ps',
       Linux   => 'top, ps',
       Solaris => 'top, ps',
       Win32   => 'taskman',
    },
    ProcTime => {
       AIX     => 'top, ps',
       Darwin  => 'top, ps',
       FreeBSD => 'top, ps',
       HPUX    => 'top, ps',
       Linux   => 'top, ps',
       Solaris => 'top, ps',
       Win32   => 'taskman',
    },
    ProcState => {
       AIX     => 'top, ps',
       Darwin  => 'top, ps',
       FreeBSD => 'top, ps',
       HPUX    => 'top, ps',
       Linux   => 'top, ps',
       Solaris => 'top, ps',
       Win32   => 'taskman',
    },
    ProcFd => {
       AIX     => 'lsof',
       Darwin  => 'lsof',
       FreeBSD => 'lsof',
       HPUX    => 'lsof',
       Linux   => 'lsof',
       Solaris => 'lsof',
       Win32   => '',
    },
    ProcStat => {
       AIX     => 'top, ps',
       Darwin  => 'top, ps',
       FreeBSD => 'top, ps',
       HPUX    => 'top, ps',
       Linux   => 'top, ps',
       Solaris => 'top, ps',
       Win32   => 'taskman',
    },
    FileSystemUsage => {
       AIX     => 'df',
       Darwin  => 'df',
       FreeBSD => 'df',
       HPUX    => 'df',
       Linux   => 'df',
       Solaris => 'df',
       Win32   => '',
    },
    NetRoute => {
       AIX     => '',
       Darwin  => '',
       FreeBSD => '',
       HPUX    => '',
       Linux   => 'route -n',
       Solaris => '',
       Win32   => '',
    },
    NetInterfaceConfig => {
       AIX     => '',
       Darwin  => '',
       FreeBSD => '',
       HPUX    => '',
       Linux   => 'ifconfig',
       Solaris => 'ifconfig -a',
       Win32   => '',
    },
    NetInterfaceStat => {
       AIX     => '',
       Darwin  => '',
       FreeBSD => '',
       HPUX    => '/usr/sbin/lanadmin -g mibstats 0, netstat -i',
       Linux   => 'ifconfig',
       Solaris => '',
       Win32   => '',
    },
    NetConnection => {
       AIX     => '',
       Darwin  => '',
       FreeBSD => '',
       HPUX    => '',
       Linux   => 'netstat',
       Solaris => '',
       Win32   => '',
    },
    Tcp => {
       Linux   => 'cat /proc/net/snmp',
       Solaris => 'netstat -s -P tcp',
    },
);

sub warning_comment {
    my $self = shift;

    return "WARNING: this file was generated by $0
on $self->{timestamp}.
Any changes made here will be LOST.";
}

sub c_warning_comment {
    my $self = shift;
    my $comment = $self->warning_comment;
    $comment =~ s/^/ * /mg;
    return <<EOF
/*****************************************************
$comment
 *****************************************************/
EOF
}

sub generate {
    my($lang, $dir) = @_ ? @_ : @ARGV;

    my $mtime = (stat __FILE__)[9];

    my $cwd = cwd();
    unless (-d $dir) {
        die "Invalid build directory '$dir'";
    }

    chdir $dir;
    my(%param) = (
        build_dir => $dir,
        mtime => $mtime,
    );

    my $package = __PACKAGE__ . "::$lang";
    eval "require $package";

    unless (defined %{$package ."::"}) {
        die "unsupported language: $lang";
    }
    $@ = '';

    my $wrapper = $package->new(%param);
    unless ($wrapper->uptodate($wrapper->sources)) {
        eval {
            $wrapper->start();

            my $mappings = $wrapper->get_mappings;
            for my $func (@$mappings) {
                $wrapper->generate_class($func);
            }

            $wrapper->finish;
        };
    }
    die $@ if $@;
    chdir $cwd;
}

sub new {
    my $class = shift;
    return bless {
        timestamp => scalar localtime,
        @_
    }, $class;
}

sub uptodate {
    my $self = shift;
    for my $file (@_) {
        my $mtime = (stat $file)[9];
        if ($mtime > $self->{mtime}) {
            print "$file up-to-date\n";
        }
        else {
            print "$file needs update\n";
            return 0;
        }
    }
    return 1;
}

my(%warning_comment) = map { $_ => \&c_warning_comment } qw(c h java);

sub create {
    my($self, $file) = @_;
    my $handle = SigarWrapper::File->create($file);
    if ($file =~ /\.(\w+)$/) {
        my $comment = $warning_comment{$1};
        $handle->print($self->$comment()) if $comment;
    }
    return $self->{files}->{$file} = $handle;
}

sub start {
}

sub finish {
    my $self = shift;
    while (my($file, $handle) = each %{ $self->{files} }) {
        next unless $handle->opened;
        if ($handle->close) {
            #print "closing $file\n";
        }
        else {
            warn "close($file): $!";
        }
    }
}

my @mappings;

sub get_mappings {
    if (@mappings != 0) {
        return \@mappings;
    }

    while (my($name, $fields) = each %classes) {
        #example: FileSystemUsage -> file_system_usage
        (my $cname = $name) =~ s/([a-z])([A-Z])/$1_$2/g;
        $cname = lc $cname;

        my $func = {
            name => $name,
            cname => $cname,
        };
        push @mappings, $func;

        if (($cname =~ /^proc_(\w+)/ and !$proc_no_arg{$1}) ||
            ($cname =~ /^thread_cpu/))
        {
            $func->{num_args} = 1;
            $func->{arg_type} = 'sigar_pid_t';
            $func->{arg} = 'pid';
            $func->{is_proc} = 1;
        }
        elsif ($has_name_arg{$name}) {
            $func->{num_args} = 1;
            $func->{arg_type} = 'const char *';
            $func->{arg}  = 'name';
        }
        else {
            $func->{num_args} = 0;
        }

        if ($get_not_impl{$cname}) {
            $func->{has_get} = 0;
        }
        else {
            $func->{has_get} = 1;
        }

        my $sigar_prefix = $func->{sigar_prefix} = join '_', 'sigar', $cname;

        $func->{sigar_function} = join '_', $sigar_prefix, 'get';

        $func->{sigar_type} = join '_', $sigar_prefix, 't';

        $func->{fields} = $fields;

        for my $field (@$fields) {
            $field->{type} ||= 'Long';
        }
    }

    return \@mappings;
}

package SigarWrapper::File;

our @ISA = qw(IO::File);

my $DEVNULL = '/dev/null';
my $has_dev_null = -e $DEVNULL;

sub println {
    shift->print(@_, "\n");
}

sub create {
    my($class, $file) = @_;

    my $handle = $class->SUPER::new($file || devnull(), "w") or die "open $file: $!";
    print "generating $file\n" if $file;
    return $handle;
}

sub devnull {
    if ($has_dev_null) {
        return $DEVNULL;
    }
    else {
        return "./nul"; #win32 /dev/null equiv
    }
}

package SigarWrapper::Java;

our @ISA = qw(SigarWrapper);

my %field_types = (
    Long   => "J",
    Double => "D",
    Int    => "I",
    Char   => "C",
    String => "Ljava/lang/String;",
);

my %init = (
    String => 'null',
);

my %type = (
    String  => 'String',
);

#alias
for my $j (\%field_types, \%init, \%type) {
    $j->{'NetAddress'} = $j->{'String'};
}

#XXX kinda ugly having this here
#will consider moving elsewhere if there
#are more cases like this.
my %extra_code = (
    FileSystem => <<'EOF',
    public static final int TYPE_UNKNOWN    = 0;
    public static final int TYPE_NONE       = 1;
    public static final int TYPE_LOCAL_DISK = 2;
    public static final int TYPE_NETWORK    = 3;
    public static final int TYPE_RAM_DISK   = 4;
    public static final int TYPE_CDROM      = 5;
    public static final int TYPE_SWAP       = 6;

    public String toString() {
        return this.getDirName();
    }
EOF
    NetConnection => <<'EOF',
    public native String getTypeString();

    public native static String getStateString(int state);

    public String getStateString() {
        return getStateString(this.state);
    }
EOF
    Mem => <<'EOF',
    public String toString() {
        return
            "Mem: " +
            (this.total / 1024) + "K av, " +
            (this.used / 1024) + "K used, " +
            (this.free / 1024) + "K free";
    }
EOF
    ResourceLimit => <<'EOF',
    public static native long INFINITY();
EOF
    Swap => <<'EOF',
    public String toString() {
        return
            "Swap: " +
            (this.total / 1024) + "K av, " +
            (this.used / 1024) + "K used, " +
            (this.free / 1024) + "K free";
    }
EOF
    ProcState => <<'EOF',
    public static final char SLEEP  = 'S';
    public static final char RUN    = 'R';
    public static final char STOP   = 'T';
    public static final char ZOMBIE = 'Z';
    public static final char IDLE   = 'D';
EOF
    ProcMem => <<'EOF',
    /**
     * @deprecated
     * @see #getResident()
     */
    public long getRss() { return getResident(); }
    /**
     * @deprecated
     * @see #getSize()
     */
    public long getVsize() { return getSize(); }
EOF
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{jsrc} = 'org/hyperic/sigar';
    return $self;
}

my $jni_file = 'javasigar_generated';

sub sources {
    return map { "$jni_file.$_" } qw(c h);
}

sub start {
    my $self = shift;
    $self->SUPER::start;
    my $jsrc = $self->{jsrc};
    File::Path::mkpath([$jsrc], 0, 0755) unless -d $jsrc;
    $self->{package} = 'org.hyperic.sigar';

    $self->{cfh} = $self->create("$jni_file.c");
    my $hfh = $self->{hfh} = $self->create("$jni_file.h");

    my %field_cache;
    my $i = 0;
    while (my($class, $fields) = each %SigarWrapper::classes) {
        next if $field_cache{$class}++;
        print $hfh "#define JSIGAR_FIELDS_\U$class $i\n";
        $i++;
        my $n = 0;
        for my $field (@$fields) {
            my $name = $field->{name};
            print $hfh "#   define JSIGAR_FIELDS_\U${class}_${name} $n\n";
            $n++;
        }
        print $hfh "#   define JSIGAR_FIELDS_\U${class}_MAX $n\n";
    }
    print $hfh "#define JSIGAR_FIELDS_MAX $i\n";
}

#using mega-method pattern here
sub generate_class {
    my($self, $func) = @_;

    my $cfh = $self->{cfh};
    my $hfh = $self->{hfh};

    my $class = $func->{name};
    my $cname = $func->{cname};

    my $java_class = "$self->{package}.$class";
    (my $jni_prefix = "Java.$java_class") =~ s/\./_/g;

    my $args_proto = "";
    my $args = "";
    my $decl_string = "";
    my $get_string = "";
    my $release_string = "";

    my $jname = lcfirst $class;

    if ($func->{num_args} == 1) {
        $args = " $func->{arg}, ";
        if ($func->{is_proc}) {
            $args_proto = ", jlong pid";
        }
        else {
            $args_proto = ", jstring jname";
            $decl_string = "const char *name;";
            $get_string = "name = jname ? JENV->GetStringUTFChars(env, jname, 0) : NULL;";
            $release_string = "if (jname) JENV->ReleaseStringUTFChars(env, jname, name);";
        }
    }

    my $nativefunc = join '_', $jni_prefix, 'gather';

    my $proto = join "\n",
      "JNIEXPORT void JNICALL $nativefunc",
        "(JNIEnv *env, jobject obj, jobject sigar_obj$args_proto)";

    my $jfh = $self->create_jfile($class);

    print $cfh <<EOF if $func->{has_get};

$proto;

$proto
{
    $func->{sigar_type} s;
    int status;
    jclass cls = JENV->GetObjectClass(env, obj);
    $decl_string
    dSIGAR_VOID;

    $get_string

    status = $func->{sigar_function}(sigar,${args}&s);

    $release_string

    if (status != SIGAR_OK) {
        sigar_throw_error(env, jsigar, status);
        return;
    }

EOF

    my $jargs_proto = 'Sigar sigar';
    my $jargs = 'sigar';

    if ($func->{is_proc}) {
        $jargs_proto .= ', long pid';
        $jargs .= ", pid";
    }
    elsif ($func->{num_args} == 1) {
        $jargs_proto .= ', String name';
        $jargs .= ", name";
    }

    my $cache_field_ids = 1;

    my $uid = 0;

    for my $field (@{ $func->{fields} }) {
        $uid +=
            SigarWrapper::hash($field->{type}) +
            SigarWrapper::hash($field->{name});
    }

    print $jfh <<EOF;
package $self->{package};

import java.util.HashMap;
import java.util.Map;

/**
 * $class sigar class.
 */
public class $class implements java.io.Serializable {

    private static final long serialVersionUID = ${uid}L;

    public $class() { }

    public native void gather($jargs_proto) throws SigarException;

    /**
     * This method is not intended to be called directly.
     * use Sigar.get$class() instead.
     * \@exception SigarException on failure.
     * \@see $self->{package}.Sigar#get$class
     */
    static $class fetch($jargs_proto) throws SigarException {
        $class $jname = new $class();
        $jname.gather($jargs);
        return $jname;
    }

EOF

    my(@copy, @tostring);
    my $define = "JAVA_SIGAR_SET_FIELDS_\U$class";
    my @macro = ("\#define $define(cls, obj, s)");
    my $init_define = "JAVA_SIGAR_INIT_FIELDS_\U$class";
    my $field_class_ix = "JSIGAR_FIELDS_\U$class";
    my $field_class_ix = "JSIGAR_FIELDS_\U$class";
    my $field_class_max = $field_class_ix . '_MAX';
    my $field_class = "jsigar->fields[$field_class_ix]";

    my @init_fields = ("#define $init_define(cls)",
                       "    if (!$field_class) {",
                       "        $field_class = ",
                       "            malloc(sizeof(*$field_class));",
                       "        $field_class->classref = ",
                       "            (jclass)JENV->NewGlobalRef(env, cls);",
                       "        $field_class->ids = ",
                       "            malloc($field_class_max *",
                       "                   sizeof(*$field_class->ids));");

    for my $field (@{ $func->{fields} }) {
        my $type = $field->{type};
        my $name = $field->{name};
        my $member = $field->{member} || $name;
        my $desc = $field->{desc} || $name;
        (my $jname = $name) =~ s/_(\w)/\u$1/g;
        my $sig = qq("$field_types{$type}");
        my $set = "JENV->Set${type}Field";

        my $field_ix = $field_class_ix . "_\U$name";
        my $get_id = qq|JENV->GetFieldID(env, cls, "$jname", $sig)|;
        my $id_cache = "$field_class->ids[$field_ix]";

        my $id_lookup = $cache_field_ids ?
          $id_cache : $get_id;

        push @init_fields,
          "        $id_cache = ",
          "            $get_id;";

        push @macro,
          qq|    $set(env, obj, $id_lookup, s.$member);|;

        my $init = $init{$type} || '0';
        my $jtype = $type{$type} || lcfirst($type);
        my $platforms = SigarWrapper::supported_platforms($field->{plat});

        print $jfh "    $jtype $jname = $init;\n\n";
        push @copy, "        copy.$jname = this.$jname;\n";
        push @tostring, $jname;

        #documentation
        print $jfh "    /**\n";
        print $jfh "     * Get the $desc.<p>\n";
        print $jfh "     * Supported Platforms: $platforms.\n";
        print $jfh "     * <p>\n";
        if (my $cmd = ($field->{cmd} || $SigarWrapper::cmds{$class})) {
            print $jfh "     * System equivalent commands:<ul>\n";
            for my $p (sort keys %$cmd) {
                print $jfh "     * <li> $p: <code>$cmd->{$p}</code><br>\n";
            }
            print $jfh "     * </ul>\n";
        }
        print $jfh "     * \@return $desc\n";
        print $jfh "     */\n";

        print $jfh "    public $jtype get\u$jname() { return $jname; }\n";
    }

    print $jfh "\n    void copyTo($class copy) {\n", @copy, "    }\n";

    my $code = $extra_code{$class};
    if ($code) {
        print $jfh $code;
    }

    my $num_fields = @tostring;
    print $jfh "\n    public Map toMap() {\n";
    print $jfh "        Map map = new HashMap();\n";
    for (my $i=0; $i<$num_fields; $i++) {
        my $jfield = $tostring[$i];
        my $sfield = "str${jfield}";
        print $jfh "        String $sfield = \n";
        print $jfh "            String.valueOf(this.$jfield);\n";
        print $jfh qq{        if (!"-1".equals($sfield))\n};
        print $jfh qq{            map.put("\u$jfield", $sfield);\n};
    }
    print $jfh "        return map;\n";
    print $jfh "    }\n";

    if (!$code or $code !~ /toString/) {
        print $jfh "\n    public String toString() {\n";
        print $jfh "        return toMap().toString();\n";
        print $jfh "    }\n";
    }

    push @init_fields, "    }";

    if ($cache_field_ids) {
        print $hfh join(' \\' . "\n", @init_fields), "\n\n";
        print $cfh "\n\n    $init_define(cls);\n\n" if $func->{has_get};
    }
    else {
        print $hfh "#define $init_define(cls)\n";
    }

    print $hfh join(' \\' . "\n", @macro), "\n\n";
    print $cfh "\n\n    $define(cls, obj, s);" if $func->{has_get};

    print $cfh "\n}\n" if $func->{has_get};
    print $jfh "\n}\n";

    close $jfh;
}

sub finish {
    my $self = shift;
    $self->SUPER::finish;
}

sub create_jfile {
    my($self, $name) = @_;
    my $jsrc = $self->{jsrc};
    my $jfile = "$jsrc/$name.java";
    if (-e "../../src/$jsrc/$name.java") {
        print "skipping $jfile\n";
        #dont generate .java if already exists
        $jfile = undef;
    }
    return $self->create($jfile);
}

package SigarWrapper::Perl;

our @ISA = qw(SigarWrapper);

my %field_types = (
    Long   => "sigar_uint64_t",
    Double => "double",
    Int    => "IV",
    Char   => "char",
    String => "char *",
    NetAddress => "Sigar::NetAddress",
);

my $xs_file = 'Sigar_generated.xs';

sub sources {
    return $xs_file;
}

sub start {
    my $self = shift;
    $self->SUPER::start;
    $self->{xfh} = $self->create($xs_file);
}

sub generate_class {
    my($self, $func) = @_;

    my $fh = $self->{xfh};
    my $class = $func->{name};
    my $cname = $func->{cname};
    my $perl_class = "Sigar::$class";
    my $proto = 'VALUE obj';
    my $args = 'sigar';

    if ($func->{num_args} == 1) {
        $args .= ", $func->{arg}";
    }

    print $fh "\nMODULE = Sigar   PACKAGE = Sigar   PREFIX = sigar_\n\n";

    print $fh <<EOF if $func->{has_get};
$perl_class
$cname($args)
    Sigar sigar
EOF
    if ($func->{arg}) {
        print $fh "    $func->{arg_type} $func->{arg}\n" if $func->{has_get};
    }

    print $fh <<EOF if $func->{has_get};

    PREINIT:
    int status;

    CODE:
    RETVAL = safemalloc(sizeof(*RETVAL));
    if ((status = $func->{sigar_function}($args, RETVAL)) != SIGAR_OK) {
        SIGAR_CROAK(sigar, "$cname");
    }

    OUTPUT:
    RETVAL
EOF

  print $fh <<EOF;

MODULE = Sigar   PACKAGE = $perl_class   PREFIX = sigar_

void
DESTROY(obj)
    $perl_class obj

    CODE:
    safefree(obj);

EOF

    for my $field (@{ $func->{fields} }) {
        my $name = $field->{name};
        my $type = $field_types{ $field->{type} };

        print $fh <<EOF;
$type
$name($cname)
    $perl_class $cname

    CODE:
    RETVAL = $cname->$name;

    OUTPUT:
    RETVAL

EOF
    }
}

sub finish {
    my $self = shift;
    $self->SUPER::finish;
}

package SigarWrapper::Ruby;

our @ISA = qw(SigarWrapper);

our %field_types = (
    Long   => "rb_ll2inum",
    Double => "rb_float_new",
    Int    => "rb_int2inum",
    Char   => "CHR2FIX",
    String => "rb_str_new2",
    NetAddress => "rb_sigar_net_address_to_string",
);

my $rx_file = 'rbsigar_generated.rx';

sub sources {
    return $rx_file;
}

sub start {
    my $self = shift;
    $self->SUPER::start;
    $self->{cfh} = $self->create($rx_file);
}

sub add_method {
    my($self, $class, $name) = @_;
    push @{ $self->{methods}->{$class} }, $name;
}

sub generate_class {
    my($self, $func) = @_;

    my $fh = $self->{cfh};
    my $class = $func->{name};
    my $cname = $func->{cname};
    my $ruby_class = "rb_cSigar$class";
    my $proto = 'VALUE obj';
    my $args = 'sigar';

    if ($func->{num_args} == 1) {
        my $arg_type;
        if ($func->{is_proc}) {
            $arg_type = 'NUM2UINT';
        }
        else {
            $arg_type = 'StringValuePtr';
        }
        $proto .= ", VALUE $func->{arg}";
        $args .= ", $arg_type($func->{arg})";
    }

    print $fh <<EOF if $func->{has_get};
static VALUE $ruby_class;

static VALUE rb_sigar_$cname($proto)
{
    int status;
    sigar_t *sigar = rb_sigar_get(obj);
    $func->{sigar_type} *RETVAL  = malloc(sizeof(*RETVAL));

    if ((status = $func->{sigar_function}($args, RETVAL)) != SIGAR_OK) {
        rb_raise(rb_eArgError, "%s", sigar_strerror(sigar, status));
    }

    return Data_Wrap_Struct($ruby_class, 0, rb_sigar_free, RETVAL);
}
EOF

    for my $field (@{ $func->{fields} }) {
        my $name = $field->{name};
        my $type = $field_types{ $field->{type} };

        $self->add_method($class, $name);

        print $fh <<EOF;
static VALUE rb_sigar_${class}_${name}(VALUE self)
{
    $func->{sigar_type} *$cname;
    Data_Get_Struct(self, $func->{sigar_type}, $cname);
    return $type($cname->$name);    
}
EOF
    }
}

sub finish {
    my $self = shift;

    my $fh = $self->{cfh};

    print $fh "static void rb_sigar_define_module_methods(VALUE rclass)\n{\n";

    my $mappings = SigarWrapper::get_mappings();

    for my $func (@$mappings) {
        my $name = $func->{cname};
        my $args = $func->{num_args};
        next unless $func->{has_get};
        print $fh qq{    rb_define_method(rclass, "$name", rb_sigar_$name, $args);\n};
    }

    for my $class (sort keys %{ $self->{methods} }) {
        my $rclass = "rb_cSigar$class";
        print $fh qq{    $rclass = rb_define_class_under(rclass, "$class", rb_cObject);\n};
        for my $method (@{ $self->{methods}->{$class} }) {
            print $fh qq{    rb_define_method($rclass, "$method", rb_sigar_${class}_$method, 0);\n};
        }
    }

    print $fh "}\n";

    $self->SUPER::finish;
}

package SigarWrapper::PHP;

our @ISA = qw(SigarWrapper);

our %field_types = (
    Long   => "RETURN_LONG",
    Double => "RETURN_DOUBLE",
    Int    => "RETURN_LONG",
    Char   => "RETURN_LONG",
    String => "PHP_SIGAR_RETURN_STRING",
    NetAddress => "PHP_SIGAR_RETURN_NETADDR",
);

my $php_file = 'php_sigar_generated.c';

sub sources {
    return $php_file;
}

sub start {
    my $self = shift;
    $self->SUPER::start;
    $self->{cfh} = $self->create($php_file);
}

sub generate_class {
    my($self, $func) = @_;

    my $cfh = $self->{cfh};
    my $class = $func->{name};
    my $cname = $func->{cname};
    my $php_class = "Sigar::$class";
    my $parse_args = "";
    my $vars = "";
    my $args = 'sigar';
    my $arginfo = $args;

    if ($func->{num_args} == 1) {
        if ($func->{is_proc}) {
            $parse_args = 'zSIGAR_PARSE_PID;';
            $arginfo .= '_pid';
            $vars = "long $func->{arg};\n";
        }
        else {
            $parse_args .= 'zSIGAR_PARSE_NAME;';
            $arginfo .= '_name';
            $vars = "char *$func->{arg}; int $func->{arg}_len;\n";
        }
        $args .= ", $func->{arg}";
    }

    my $prefix = "php_$func->{sigar_prefix}_";
    my $functions = $prefix . 'functions';
    my $handlers = $prefix . 'object_handlers';
    my $init = $prefix . 'init';

    my $ctor = $prefix . 'new';

    my(@functions);

    for my $field (@{ $func->{fields} }) {
        my $name = $field->{name};
        my $type = $field_types{ $field->{type} };
        my $method = $prefix . $name;

        push @functions, { name => $name, me => $method };
        print $cfh <<EOF;
static PHP_FUNCTION($method)
{
    $func->{sigar_type} *$cname = ($func->{sigar_type} *)zSIGAR_OBJ;
    $type($cname->$name);
}
EOF
    }

    print $cfh <<EOF;
static zend_object_handlers $handlers;

static zend_object_value $ctor(zend_class_entry *class_type TSRMLS_DC)
{
    return php_sigar_ctor(php_sigar_obj_dtor,
                          &$handlers,
                          NULL,
                          class_type);
}

static zend_function_entry ${functions}[] = {
EOF

    for my $func (@functions) {
        print $cfh "    PHP_ME_MAPPING($func->{name}, $func->{me}, NULL)\n";
    }

    print $cfh <<EOF;
    {NULL, NULL, NULL}
};
EOF

    print $cfh <<EOF;
static void $init(void)
{
    zend_class_entry ce;

    PHP_SIGAR_INIT_HANDLERS($handlers);
    INIT_CLASS_ENTRY(ce, "$php_class", $functions);
    ce.create_object = $ctor;
    zend_register_internal_class(&ce TSRMLS_CC);
}
EOF

    print $cfh <<EOF if $func->{has_get};
static PHP_FUNCTION($func->{sigar_function})
{
    int status;
    zSIGAR;

    $func->{sigar_type} *RETVAL = emalloc(sizeof(*RETVAL));
    $vars
    $parse_args

    if ((status = $func->{sigar_function}($args, RETVAL)) != SIGAR_OK) {
        efree(RETVAL);
        RETURN_FALSE;
    }
    else {
        php_sigar_obj_new("$php_class", return_value)->ptr = RETVAL;
    }
}
EOF
}

sub finish {
    my $self = shift;

    my $mappings = $self->get_mappings;
    my $cfh = $self->{cfh};
    my $nl = '\\' . "\n";

    print $cfh "#define PHP_SIGAR_FUNCTIONS $nl";
    for my $func (@$mappings) {
        next unless $func->{has_get};
        #XXX PHP_ME_MAPPING has another arg in 5.2
        print $cfh "    PHP_ME_MAPPING($func->{cname}, $func->{sigar_function}, NULL)";
        if ($func == $mappings->[-1]) {
            print $cfh "\n";
        }
        else {
            print $cfh $nl;
        }
    }

    print $cfh "#define PHP_SIGAR_INIT $nl";
    for my $func (@$mappings) {
        print $cfh "    php_$func->{sigar_prefix}_init()";
        if ($func == $mappings->[-1]) {
            print $cfh "\n";
        }
        else {
            print $cfh ";$nl";
        }
    }

    $self->SUPER::finish;
}

#XXX not currently supporting netware
package SigarWrapper::Netware;

our @ISA = qw(SigarWrapper);

sub start {
    my $self = shift;
    $self->SUPER::start;
    $self->{dfh} = $self->create('javasigar_generated.def');
}

sub finish {
    my $self = shift;
    my $fh = $self->{dfh};
    for my $func (@{ $self->{nativefunc} }) {
        #$fh->println($nativefunc) if $impl;
    }
    my $jsigar = "../../src/jni/javasigar.c";
    my(%alias) = (x => 'Sigar');
    open JSIGAR, $jsigar or die "open $jsigar: $!";
    while (<JSIGAR>) {
        next unless /SIGAR_JNI([a-z]?)\(([A-Za-z_]+)\)/;
        my $class = "";
        if ($1) {
            $class = $alias{$1} . "_";
        }
        $fh->println("Java_org_hyperic_sigar_$class$2");
    }
    close JSIGAR;

    $self->SUPER::finish;
}

1;
__END__