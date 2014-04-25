#!/usr/bin/perl

# Title:       NDSD Segfaults when a Volume is being accessed
# Description: Checks for NDSD segfaults.
# Modified:    2014 Apr 25

##############################################################################
#  Copyright (C) 2014 SUSE LLC
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
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

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
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=SegFaults",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7007882",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=666582"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub ndsdSegFault {
	SDP::Core::printDebug('> ndsdSegFault', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /kernel.*ndsd.*segfault at 0000000000000121 rip 00002aaaaab.*rsp 00000000.*error 4/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ndsdSegFault(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< ndsdSegFault", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $RPM_NAME = 'novell-ncpenc';
	my $VERSION_TO_COMPARE = '5.1.5-0.31';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		if ( $RPM_COMPARISON <= 0 ) {
			if ( ndsdSegFault() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Detected NDSD segfault");
			} else {
				my %HOST_INFO = SDP::SUSE::getHostInfo();
				if ( $HOST_INFO{'oes'} ) {
					if ( $HOST_INFO{'oesmajor'} == 2 && $HOST_INFO{'oespatchlevel'} == 3 ) {
						SDP::Core::updateStatus(STATUS_WARNING, "Detected potential NDSD segfault");
					} else {
						SDP::Core::updateStatus(STATUS_ERROR, "ABORT: Missing OES2 SP3, skipping NDSD segfault check.");
					}
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "ABORT: OES Not Installed, skipping NDSD segfault check.");
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ABORT: Newer ncp engine, skipping NDSD segfault check.");
		}			
	}
SDP::Core::printPatternResults();

exit;

