#!/usr/bin/perl

# Title:       Validate NMAS LDAP extensions
# Description: Verify all normal NMAS LDAP extensions are present on the LDAP server object
# Modified:    2013 Jun 21

##############################################################################
#  Copyright (C) 2013 SUSE LLC
##############################################################################
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)

##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=NMAS",
	PROPERTY_NAME_COMPONENT."=Extensions",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3947462"
);



my %NMAS_LDAP_EXTENSION = ( # required NMAS LDAP server extensions
	'2.16.840.1.113719.1.39.42.100.1' => 1,
	'2.16.840.1.113719.1.39.42.100.3' => 1,
	'2.16.840.1.113719.1.39.42.100.5' => 1,
	'2.16.840.1.113719.1.39.42.100.7' => 1,
	'2.16.840.1.113719.1.39.42.100.9' => 1,
	'2.16.840.1.113719.1.39.42.100.11' => 1,
	'2.16.840.1.113719.1.39.42.100.13' => 1,
	'2.16.840.1.113719.1.39.42.100.15' => 1,
	'2.16.840.1.113719.1.39.42.100.17' => 1,
	'2.16.840.1.113719.1.39.42.100.19' => 1,
	'2.16.840.1.113719.1.39.42.100.21' => 1,
	'2.16.840.1.113719.1.39.42.100.23' => 1,
	'2.16.840.1.113719.1.39.42.100.25' => 1,
);
my $EXT_MIN = scalar keys %NMAS_LDAP_EXTENSION;

##############################################################################
# Local Function Definitions
##############################################################################

sub checkLdapNmasExtensions {
	SDP::Core::printDebug('> checkLdapNmasExtensions', 'BEGIN');
	my $RCODE = 0;
	my $NOVELL_LDAP = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ldap.txt';
	my $SECTION = 'ldapsearch -x.*objectclass'; # root DSE
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /^supportedExtension:\s/i ) {
				@LINE_CONTENT = split(/:\s+/, $_);
				if ( $NMAS_LDAP_EXTENSION{$LINE_CONTENT[1]} ) {
					SDP::Core::printDebug("NMAS", $LINE_CONTENT[1]);
					$RCODE++;
				} else {
					SDP::Core::printDebug("OTHER", $LINE_CONTENT[1]);
				}
			} elsif ( /vendorName.*Novell/i ) {
				$NOVELL_LDAP++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkLdapNmasExtensions(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("RESULTS", "Found: $RCODE, Minimum Extensions: $EXT_MIN");
	if ( $NOVELL_LDAP ) {
		if ( $RCODE < $EXT_MIN ) {
			my $DIFF = $EXT_MIN-$RCODE;
			SDP::Core::updateStatus(STATUS_CRITICAL, "NMAS LDAP Server Extensions Missing: " . $DIFF);
		} else {
			SDP::Core::updateStatus(STATUS_PARTIAL, "All NMAS LDAP Server Extensions Found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkLdapNmasExtensions(): Root DSE Failure or Invalid Novell LDAP Server");
	}
	SDP::Core::printDebug("< checkLdapNmasExtensions", "Returns: $RCODE");
	return $RCODE;
}

sub checkLumLdapNmasExtensions {
	SDP::Core::printDebug('> checkLumLdapNmasExtensions', 'BEGIN');
	my $RCODE = 0;
	my $NOVELL_LDAP = 0;
	my @LINE_CONTENT = ();
	my $PREFERRED_SERVER = 'Unknown';
	my $FILE_OPEN = 'novell-lum.txt';
	my $SECTION = 'namconfig get preferred-server';
	my @CONTENT = ();

	# find the preferred server if any
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /preferred-server/i ) {
				s/\s+|\'|\"//g;
				@LINE_CONTENT = split(/=/, $_);
				$PREFERRED_SERVER = $LINE_CONTENT[1];
			}
		}
	}

	$SECTION = 'ldapsearch -x.*objectclass'; # root DSE
	@CONTENT = ();
	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /^supportedExtension:\s/i ) {
				@LINE_CONTENT = split(/:\s+/, $_);
				if ( $NMAS_LDAP_EXTENSION{$LINE_CONTENT[1]} ) {
					SDP::Core::printDebug("NMAS", $LINE_CONTENT[1]);
					$RCODE++;
				} else {
					SDP::Core::printDebug("OTHER", $LINE_CONTENT[1]);
				}
			} elsif ( /vendorName.*Novell/i ) {
				$NOVELL_LDAP++;
			}
		}
	}
	SDP::Core::printDebug("RESULTS", "Found: $RCODE, Minimum Extensions: $EXT_MIN");
	if ( $NOVELL_LDAP ) {
		if ( $RCODE < $EXT_MIN ) {
			my $DIFF = $EXT_MIN-$RCODE;
			SDP::Core::updateStatus(STATUS_WARNING, "Preferred LUM LDAP Server ($PREFERRED_SERVER), NMAS Extensions Missing: " . $DIFF);
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "All NMAS Preferred LUM LDAP Server Extensions Found");
		}
	}
	SDP::Core::printDebug("< checkLumLdapNmasExtensions", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $RPM_NAME = 'novell-nmas';
	my $VERSION_TO_COMPARE = '2.3';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		if ( $RPM_COMPARISON >= 0 ) {
			checkLdapNmasExtensions();
			checkLumLdapNmasExtensions();
		}			
	}
SDP::Core::printPatternResults();

exit;

