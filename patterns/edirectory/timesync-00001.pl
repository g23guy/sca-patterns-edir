#!/usr/bin/perl

# Title:       Verify eDirectory Time Synchronization
# Description: Checks ndsrepair output to ensure that time is in sync on known servers
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
#   Tregaron Bayly (tbayly@novell.com)

##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;
use SDP::eDir;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=Time",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003223"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub get_ndsrepair_t {
  my $FILE_OPEN                = 'novell-edir.txt';
  my $SECTION                  = 'ndsrepair -T';
  my @CONTENT                  = ();
  my $return = "";

  if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
    for (my $i = 0; $i <= $#CONTENT; $i++) {
      if ( $CONTENT[$i] =~ "Processing server" && (($i + 1) < $#CONTENT)) { # Next line is the one we want...
        my ($serverdn, undef, undef, undef, $insync, undef) = split (/\s+/, $CONTENT[$i+1]); # This will fail on servernames with spaces..
        if (!$insync =~ "Yes") { 
           $return = $return . "$serverdn ";
        }
      }
    }
  } 
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
  }
  return $return;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
 
  SDP::eDir::eDirValidation();

	if (my $return = get_ndsrepair_t) {
    my $message = "";
    my @servers = split(/ /,$return);
    if ($#servers > 0) { $message = "Time is out of sync on the following servers: "; }
    else { $message = "Time is out of sync on the following server: "; }
    SDP::Core::updateStatus(STATUS_WARNING, "$message $return");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Time is in sync on all known servers");
	}

SDP::Core::printPatternResults();


exit($GSTATUS);


