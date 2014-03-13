#!/usr/bin/perl -w

# Title:       Check for replication errors
# Description: This pattern checks the output of ndsrepair -E for any replication errors.  Replication errors will only trigger a warning status since some replication errors are innocuous
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
#     Tregaron Bayly (tbayly@novell.com)
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
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=Replicas",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3564075"
);



##############################################################################
# Local Function Definitions
##############################################################################

sub getPartitionsAndStatus {
  my $array_ref = $_[0];
  my @output = ();
  my $dn = "";
  my $errors = 0;
  my $in_partition = 0;

  if (SDP::Core::getSection("novell-edir.txt", "ndsrepair -E", \@output)) {
    foreach $_ (@output) {
      if (($_ =~ "Partition" && $in_partition == 0)
           || $_ =~ "Finish" ) { # We've started a new block or ended all blocks
         $in_partition = 0;
         push @$array_ref, ( { dn => $dn,
                               errors => $errors} );
         $dn = "";
         $errors = 0;
      }
      if ($_ =~ "Partition") { 
          $in_partition = 1;
          (undef, $dn) = split(/Partition: /, $_);
      }
      elsif ($in_partition == 1 && $_ =~ "-(6|7)") { # caught sync error in partition block
        $errors = 1;
      }
    }
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"ndsrepair -E\" section in novell-edir.txt");
  }
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();

        SDP::eDir::eDirValidation();
        my @partitions = ();
        my $err_count = 0;
        my $partition_list = "";
        getPartitionsAndStatus(\@partitions);

        for (my $i = 0; $i <= $#partitions; $i++) {
          if ($partitions[$i]{'errors'} == 1) {
            $err_count++;
            if ($err_count > 1) { $partition_list = "$partition_list, $partitions[$i]{'dn'}"; }
            else { $partition_list = "$partitions[$i]{'dn'}"; } 
          }
        }

        my $string = ($err_count == 1 ? "The following partition has" : "The following partitions have");

        if ($err_count) { 
          SDP::Core::updateStatus(STATUS_WARNING, "$string one or more sync errors: $partition_list"); 
        } else {
				SDP::Core::updateStatus(STATUS_ERROR, "No partitions have sync errors");
			}

SDP::Core::printPatternResults();

exit;


