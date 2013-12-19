#!/usr/bin/perl

# Title:       Check that the Audit agent is updated to a current level
# Description: This pattern will check for the Novell Audit platform agent (which is used to send events to the Audit SLS, Novell Sentinel, or Novell Identity Audit) and ensure it has been updated to the latest version.
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
#

#  Authors/Contributors:
#   Shaun Price (sprice@novell.com)
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
	PROPERTY_NAME_CATEGORY."=Audit",
	PROPERTY_NAME_COMPONENT."=Revision",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7000686"
);





##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $AUDITAGENT_RPM='novell-AUDTplatformagent';
	my $AUDITAGENT_RPMV='2.0.2-55';

	my $RPM_COMPARED = SDP::SUSE::compareRpm($AUDITAGENT_RPM, $AUDITAGENT_RPMV);
	if ( $RPM_COMPARED == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $AUDITAGENT_RPM Not Installed");
	} elsif ( $RPM_COMPARED > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple $AUDITAGENT_RPM Versions Installed");
	} else {
		if ( $RPM_COMPARED < 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Audit platform agent is behind the currently released version");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Audit platform agent version appears valid");
		}
	}
SDP::Core::printPatternResults();
exit;


