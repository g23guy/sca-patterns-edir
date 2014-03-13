#!/usr/bin/perl -w

# Title:       Check for exref-only server
# Description: This pattern is intended to check for a server that does not contain a copy of the replica containing its ncp server object.  Unfortunately this is impossible to detect from ndsrepair output on a server, so this pattern only detects machines with no replicas at all based on the root most entry depth.
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
#    Tregaron Bayly (tbayly@novell.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::eDir;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=DIB",
	PROPERTY_NAME_COMPONENT."=Replicas",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3955264"
);



##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();

	SDP::eDir::eDirValidation();
	my %ndsstat = SDP::eDir::eDirStatus();

	if ($ndsstat{'Root Most Entry Depth'} == -1) {
		SDP::Core::updateStatus(STATUS_WARNING, "Server does not hold a replica of its NCP server object");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "At least one replica is on the server");
	}
SDP::Core::printPatternResults();

exit;

