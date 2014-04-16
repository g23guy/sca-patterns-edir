#!/usr/bin/perl -w

# Title:       Check eDirectory thread usage
# Description: This pattern checks eDirectory thread usage.  First it checks whether the maximum number of threads have been spawned, then it checks whether the threads are idle.  If we are below the maximum number of threads we are always healthy (since more threads can be spawned if needed).  If we are at the maximum number of threads we are healthy unless more than 80% of the threads are working.
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
#    Tregaron Bayly: tbayly@novell.com
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;    # should be same as -w command option
use SDP::Core;
use SDP::SUSE;
use SDP::eDir;


##############################################################################
# Constants
##############################################################################

use constant THREAD_UTIL => "THREAD_UTIL";       


##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=Threads",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=10100480"
);



##############################################################################
# Feature Subroutines
##############################################################################

sub get_eDir_threads {
  my @output = ();
  my $filename = "novell-edir.txt";
  my $string = "ndstrace -c threads";
  my ($pool_idle, $pool_total, $waiting_current, $waiting_peak, $pool_peak);
  my $total_threads = $_[0];
  my $working_threads = $_[1];
  $pool_idle = undef;
  $pool_total = undef;
  $waiting_current = undef;
  $waiting_peak = undef;

  if (SDP::Core::getSection($filename, $string, \@output)) {

  foreach $_ (@output) {
    if (/^Pool Workers/i) {
      my ($title, $data) = split (/:/, $_);
      ($pool_idle, $pool_total, $pool_peak) = split (/,/, $data);
      $pool_idle =~ s/(\s)|(Idle)//g;
      $pool_total =~ s/(\s)|(Total)//g;
      $$total_threads = $pool_total;
    }
    elsif (/^Waiting Work/) {
      my ($title, $data) = split (/:/, $_);
      ($waiting_current, $waiting_peak) = split (/,/, $data);
      $waiting_current =~ s/(\s)|(Current)//g;
    }
  }

   if (defined($pool_total) && defined($waiting_current)) {
     $$working_threads = ($pool_total - $pool_idle);
   }
   else {
      SDP::Core::updateStatus(STATUS_ERROR, "Pool total or Waiting Work threads not found");
#      debug("Pool total or Waiting Work threads undefined",$DEBUG_COLL);
   }

    unless (defined($working_threads)) { 
      SDP::Core::updateStatus(STATUS_ERROR, "No working threads found");
    }
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$string\" section in $filename");
  }
}

sub get_max_threads {
  my $filename = "novell-edir.txt";
  my $string = "ndsconfig get";
  my @output = ();
  my $max_threads = 0;

  if (SDP::Core::getSection($filename, $string, \@output)) {
    foreach $_ (@output) {
      if (/^n4u.server.max-threads/i) {
        (undef, $max_threads) = split (/=/,$_);
      }
    }
    return $max_threads;
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$string\" section in $filename");
  }

}


##############################################################################
# Main
##############################################################################

SDP::Core::processOptions();

	# pattern specific logic - pattern order important

  my $total_threads = 0;
  my $working_threads = 0;

  SDP::eDir::eDirValidation();
  get_eDir_threads(\$total_threads, \$working_threads);
  printDebug("Total Threads", $total_threads);
  printDebug("Working Threads", $working_threads);


  my $max_threads = get_max_threads();
  printDebug("Maximum Threads", $max_threads);
  if ($max_threads && $total_threads && $working_threads) {
    if ($total_threads < $max_threads) { 
      #We are healthy because we can grow more threads if necessary
      updateStatus(STATUS_ERROR, "Total eDirectory threads are less than maximum threads.");
    }
    elsif ($working_threads / $total_threads * 100 >= 99) {
      #We are thread bound and in trouble
      updateStatus(STATUS_CRITICAL, "Total eDirectory threads are at maximum and 99\% are working.");
    }
    elsif ($working_threads / $total_threads * 100 >= 80) {
      #We may be approaching problems
      updateStatus(STATUS_WARNING, "Total eDirectory threads are at maximum and more than 80\% are working.");
    }
    else {
      #We are healthy
      updateStatus(STATUS_ERROR, "Total eDirectory threads are at maximum, but less than 80\% are working.");
    }
  }
  else {
    #We didn't get the data we needed for analysis
    SDP::Core::updateStatus(STATUS_ERROR, "Error collecting data to analyze eDirectory threads");
  }


  printPatternResults();


exit;


