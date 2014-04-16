#!/usr/bin/perl -w

# Title:       Check disk space on DIB file system
# Description: This pattern determines the mount point containing the eDirectory DIB and then checks the amount of disk space available as a percentage.  Hard-coded values of 90% full trigger a warning and 95% true trigger an error.  These values may not be relevant for all partition sizes.
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

use constant DIB_MOUNT_UTIL => "DIB_MOUNT_UTIL";       
use constant YELLOW => 90;
use constant RED => 95;


##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=DIB",
	PROPERTY_NAME_COMPONENT."=Disk",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002912"
);



##############################################################################
# Feature Subroutines
##############################################################################

sub get_dibdir {
  my @array = ();
  my $filename = "novell-edir.txt";
  my $string = "ndsconfig get";
  my $dibdir;

  if (SDP::Core::getSection($filename, $string, \@array)) {

  foreach $_ (@array) {
    if (m/n4u.nds.dibdir/i) {
      (undef, $dibdir) = split(/=/, $_);
    }
  }
  return $dibdir;
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$string\" section in $filename");
  }
}

sub get_disk_percent_used {
  my ($target_directory) = @_;
  my @output = ();
  my $filename = "basic-health-check.txt";
  my $string = "/bin/df -h";

  if (SDP::Core::getSection($filename, $string, \@output)) {

  my $target_mount = "";
  my @directory = split(/\//,$target_directory);
  my $return;

  $target_mount = get_mount_path(\@directory);
  printDebug("Mounted on", $target_mount);
  foreach $_ (@output) {
    chomp;
#     printDebug("$_", "");
    if (index($_,"%") >= 0) { 
      $_ = substr($_, (index($_,"%") - 3)); 
      my ($percent, $mountpath) = split(/% /, $_);
      $percent =~ (s/\s//g);
      if ($mountpath eq "$target_mount") {
        $return = $percent;
      }
    }
  }
  return $return;
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$string\" section in $filename");
  }
}

sub get_mount_path {
  my ($ref_directory) = @_; 
  my @output = ();
  my $filename = "fs-diskio.txt";
  my $string = "/bin/mount";

  if (SDP::Core::getSection($filename, $string, \@output)  && defined($ref_directory)) {
  my ($curr_match, $mount_path);
  my $best_match = -1;

  foreach $_ (@output) {
    my @mount_path = split(/ /, $_);
    if(defined($mount_path[2])) {

      my @mountdir = split(/\//, $mount_path[2]);
      $curr_match = check_dir_depth_match(\@mountdir, $ref_directory);
      if ($curr_match != 1 && $curr_match > $best_match) {   # we match a 0 on root, a 1 on a miss, more on everything else
        $best_match = ($curr_match == 0) ? -1 : $curr_match;
        $mount_path = $mount_path[2];
      }
     }
  }
  return $mount_path;
  }
  else {
    SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$string\" section in $filename");
  }
}

sub check_dir_depth_match {
  my ($ref_mountpath, $ref_directory) = @_;
  my $match_depth = 0;
#   printDebug("Now executing","check_dir_depth_match");

  for (my $i = 0; $i <= $#{$ref_mountpath}; $i++) {
    if (${$ref_mountpath}[$i] eq ${$ref_directory}[$i]) {
      $match_depth++;
    }
    else {
      # we either never matched, or we diverge later in
      # the mount path.  Perfect matches should never
      # hit this case.
      $match_depth = 1;
    }
  }
  return $match_depth;

}


##############################################################################
# Main
##############################################################################

SDP::Core::processOptions();

	SDP::eDir::eDirValidation();
	my $dib_dir = get_dibdir();
	printDebug("DIB directory", $dib_dir);
	if ($dib_dir =~ "Cannot find") {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find DIB Directory");
	} else {
		my $percent_full = get_disk_percent_used($dib_dir);
		printDebug("Percent Full", $percent_full);
		if ( $percent_full >= 95 ) {
			printDebug("Greater than 95%","TRUE");
			updateStatus(STATUS_CRITICAL, "File system containing the DIB is $percent_full\% full.");
		} elsif ( $percent_full >= 90 ) {
			printDebug("Greater than 90%","TRUE");
			updateStatus(STATUS_WARNING, "File system containing the DIB is $percent_full\% full.");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "File system containing the DIB is not full.");
		}
	}
	printPatternResults();

exit;

