#!/usr/bin/perl

# Title:       Check LDAP Group trustees 
# Description: Determines if the ncp server object has the necessary rights to read the LDAP Group object.  If not, the ldap server will not be able to listen on either the secure or non-secure port. 
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
#  along with this program; if not, see <http://www.gnu.org/licenses/>.
#

#  Authors/Contributors:
#   Jim Schnitter (jschnitter@novell.com)

##############################################################################

##############################################################################
# Module Definition
##############################################################################


#use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;
use SDP::eDir;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=LDAP",
	PROPERTY_NAME_COMPONENT."=Trustees",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004449"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub checkLdapTrustees {
	SDP::Core::printDebug('> checkLdapTrustees', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'novell-edir.txt';
	my $SECTION = 'ndsd.log';
	my @CONTENT = ();
	my @LINE_CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /Failed to create attribute map in UpgradeExistingLDAPGroup/ ) {
				SDP::Core::printDebug("LINE", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "LDAP Group trustee assignment needs to be reset");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "LDAP Group trustee assignment is correct");
	}
	SDP::Core::printDebug("< checkLdapTrustees", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	SDP::eDir::eDirValidation(EDIR_NOT_RUNNING);
	checkLdapTrustees();
SDP::Core::printPatternResults();

exit;
