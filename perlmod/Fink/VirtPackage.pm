#
# Fink::VirtPackage class
#
# Fink - a package manager that downloads source and installs it
# Copyright (c) 2001 Christoph Pfisterer
# Copyright (c) 2001-2003 The Fink Package Manager Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA	 02111-1307, USA.
#

package Fink::VirtPackage;

use Fink::Config qw($config $basepath);
use POSIX qw(uname);
use Fink::Status;

use strict;
use warnings;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION	 = 1.00;
	@ISA		 = qw(Exporter);
	@EXPORT		 = qw();
	@EXPORT_OK	 = qw();	# eg: qw($Var1 %Hashit &func3);
	%EXPORT_TAGS = ( );		# eg: TAG => [ qw!name1 name2! ],
}
our @EXPORT_OK;

my $the_instance = undef;

END { }				# module clean-up code here (global destructor)


### constructor

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};
	bless($self, $class);

	$self->initialize();

	$the_instance = $self;
	return $self;
}

### self-initialization

sub initialize {
	my $self = shift;
	my ($hash);
	my ($dummy);
	my ($darwin_version, $macosx_version, $cctools_version, $cctools_single_module);
	# determine the kernel version
	($dummy,$dummy,$darwin_version) = uname();

	# Now the Mac OS X version
	$macosx_version = 0;
	if (-x "/usr/bin/sw_vers") {
		$dummy = open(SW_VERS, "/usr/bin/sw_vers |") or die "Couldn't determine system version: $!\n";
		while (<SW_VERS>) {
			chomp;
			if (/(ProductVersion\:)\s*([^\s]*)/) {
				$macosx_version = $2;
				last;
			}
		}
	}

	# now find the cctools version
	if (-x "/usr/bin/ld" and -x "/usr/bin/what") {
		foreach(`what /usr/bin/ld`) {
			if (/cctools-(\d+)/) {
				$cctools_version = $1;
				last;
			}
		}
	}

	if (-x "/usr/bin/cc" and my $cctestfile = POSIX::tmpnam()) {
		system("touch ${cctestfile}.c");
		if (system("cc -o ${cctestfile}.dylib ${cctestfile}.c -dynamiclib -single_module >/dev/null 2>\&1") == 0) {
			$cctools_single_module = '1.0';
		} else {
			$cctools_single_module = undef;
		}
		unlink($cctestfile);
		unlink("${cctestfile}.c");
		unlink("${cctestfile}.dylib");
	}
	# create dummy object for kernel version
	$hash = {};
	$hash->{package} = "darwin";
	$hash->{status} = "install ok installed";
	$hash->{version} = $darwin_version."-1";
	$hash->{description} = "[virtual package representing the kernel]";
	$self->{$hash->{package}} = $hash;
	
	# create dummy object for system version, if this is OS X at all
	if ($macosx_version ne 0) {
		$hash = {};
		$hash->{package} = "macosx";
		$hash->{status} = "install ok installed";
		$hash->{version} = $macosx_version."-1";
		$hash->{description} = "[virtual package representing the system]";
		$self->{$hash->{package}} = $hash;
	}

	# create dummy object for cctools version, if version was found in Config.pm
	if (defined ($cctools_version)) {
		$hash = {};
		$hash->{package} = "cctools";
		$hash->{status} = "install ok installed";
		$hash->{version} = $cctools_version."-1";
		$hash->{description} = "[virtual package representing the developer tools]";
		$hash->{builddependsonly} = "true";
		$self->{$hash->{package}} = $hash;
	}

	# create dummy object for cctools-single-module, if supported
	if ($cctools_single_module) {
		$hash = {};
		$hash->{package} = "cctools-single-module";
        $hash->{status} = "install ok installed";
		$hash->{version} = $cctools_single_module."-1";
		$hash->{description} = "[virtual package, your dev tools support -single_module]";
		$hash->{builddependsonly} = "true";
		$self->{$hash->{package}} = $hash;
	}
	if (-f '/usr/X11R6/lib/libX11.6.dylib' ) #RANGERFIXME is .6.dylib okay for all X11R6 products?
	{
		# check the status file
		if ((Fink::Status->query_package('system-xfree86') eq 0) &&
		    (Fink::Status->query_package('xfree86-base') eq 0) &&
		    (Fink::Status->query_package('xfree86-rootless') eq 0) &&
		    (Fink::Status->query_package('xfree86-base-threaded') eq 0) &&
		    (Fink::Status->query_package('system-xfree86-43') eq 0) &&
		    (Fink::Status->query_package('system-xfree86-42') eq 0) &&
		    (Fink::Status->query_package('xfree86-base-shlibs') eq 0) &&
		    (Fink::Status->query_package('xfree86') eq 0) &&
		    (Fink::Status->query_package('system-xtools') eq 0) &&
		    (Fink::Status->query_package('xfree86-base-threaded-shlibs') eq 0) &&
		    (Fink::Status->query_package('xfree86-rootless-shlibs') eq 0))
		{
			my ($xver,$xvermaj,$xvermin,$xverrev) = check_x11_version();
			if (defined $xver)
			{
				$hash = {};
				$hash->{package} = "system-xfree86";
		       $hash->{status} = "install ok installed";
				$hash->{version} = "1:1.0-1";
				$hash->{description} = "[placeholder for user installed x11]";
				$self->{$hash->{package}} = $hash;
				$hash = {};	
				if ($xvermin eq "2")
				{
					$hash->{package} = "system-xfree86-42";
		       		$hash->{status} = "install ok installed";
					$hash->{version} = "4.2-3";
					$hash->{provides} = "x11, rman, libgl, libgl-shlibs, xft1";
				} else {
					$hash->{package} = "system-xfree86-43";
		       		$hash->{status} = "install ok installed";
					$hash->{version} = "4.3-3";
					$hash->{provides} = "x11, rman, libgl, libgl-shlibs, xft2, fontconfig1";
				}
				$hash->{description} = "[placeholder for user installed xfree86]";
				$self->{$hash->{package}} = $hash;				
			}
		}    
	}
}

### query by package name
# returns false when not installed
# returns full version when installed and configured

sub query_package {
	my $self = shift;
	my $pkgname = shift;
	my ($hash);

	if (not ref($self)) {
		if (defined($the_instance)) {
			$self = $the_instance;
		} else {
			$self = Fink::VirtPackage->new();
		}
	}

	if (not exists $self->{$pkgname}) {
		return 0;
	}
	$hash = $self->{$pkgname};
	if (not exists $hash->{version}) {
		return 0;
	}
	return $hash->{version};
}

### retreive whole list with versions
# doesn't care about installed status
# returns a hash ref, key: package name, value: hash with core fields
# in the hash, 'package' and 'version' are guaranteed to exist

sub list {
	my $self = shift;
	my ($list, $pkgname, $hash, $newhash, $field);

	if (not ref($self)) {
		if (defined($the_instance)) {
			$self = $the_instance;
		} else {
			$self = Fink::VirtPackage->new();
		}
	}


	$list = {};
	foreach $pkgname (keys %$self) {
		next if $pkgname =~ /^_/;
		$hash = $self->{$pkgname};
		next unless exists $hash->{version};

		$newhash = { 'package' => $pkgname,
								 'version' => $hash->{version} };
		foreach $field (qw(depends provides conflicts maintainer description status builddependsonly)) {
			if (exists $hash->{$field}) {
				$newhash->{$field} = $hash->{$field};
			}
		}
		$list->{$pkgname} = $newhash;
	}

	return $list;
}

### Check the installed x11 version
sub check_x11_version {
	# RANGERFIXME this is called for every invocation of fink/apt/dpkg in some cases, make me faster 
	# and better :)
	if ((! -f '/usr/X11R6/bin/xterm') or
	    (! -f '/usr/X11R6/bin/xrdb') or
	    (! -f '/usr/X11R6/bin/rman') or
	    (! -f '/usr/X11R6/lib/libX11.dylib') or
	    (! -f '/usr/X11R6/lib/libXpm.dylib') or
	    (! -f '/usr/X11R6/lib/libXaw.dylib') or
	    (! -f '/usr/X11R6/include/X11/Xlib.h') or
	    ( -e '/usr/X11R6/lib/libapplexp.1.dylib') or
	    ( -e '/usr/X11R6/lib/tenon') or
	    ((! -x '/usr/X11R6/bin/XDarwin') and
	    (! -x '/usr/X11R6/bin/Xquartz')))
	{
		return undef;
	}
	# RANGERFIXME eek, I am crap at perl regexes
	my $XF_VERSION=`find /usr/X11R6/man -type f | xargs grep "Version.*XFree86" 2>/dev/null | /usr/bin/head -1`;
	$XF_VERSION =~ s,^.*Version\S* ([^\s]+) .*$,$1,;
	chomp $XF_VERSION;
	my $XF_MAJOR = $XF_VERSION;
	$XF_MAJOR =~ s/^([^\.]+).*$/$1/;
	my $XF_MINOR = $XF_VERSION;
	$XF_MINOR =~ s/^[^\.]+\.([^\.]+).*$/$1/;
	my $XF_REVISION = $XF_VERSION;
	$XF_REVISION =~ s/^[^\.]+\.[^\.]+\.([^\$]*)/$1/;
	return ($XF_VERSION,$XF_MAJOR,$XF_MINOR,$XF_REVISION);
}
### EOF
1;
