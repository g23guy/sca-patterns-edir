#!/usr/bin/perl -w

# Title:       Determine ndsd memory size 
# Description: This pattern first determines if ndsd is running at the time the basic-health-check.txt was generated.  If so, the script calculates the current virtual memory size.  The hard-coded thresholds are < 1Gb Green; < 1.8 Gb Yellow and above 1.8 Gb Red.  This pattern currently does not work with multiple instances or 64-bit eDirectory.
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
#     Jim Schnitter (jschnitter@novell.com)
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
	PROPERTY_NAME_COMPONENT."=Memory",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7002714"
);



sub ndsd_memory_size {

	my $FILE_SERVICE   = "basic-health-check.txt";
        my $SECTION        = "/bin/ps axwwo user,pid,ppid,%cpu,%mem,vsz,rss,stat,time,cmd";
        my @CONTENT        = ();
	my $mem = 0;
	my $line;

        if ( SDP::Core::getSection($FILE_SERVICE, $SECTION, \@CONTENT) ) {
                foreach $line (@CONTENT) {
		if ($line =~ m/(\w*)\s*(\d*)\s*(\d*)\s*(\w*\.\w*)\s*(\w*\.\w*)\s*(\d*).*ndsd$/) {

			# Note $6 holds the number of K in the running process
			$mem = $6;
		}
		} # end foreach

	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_SERVICE");
        }
	
	return $mem;	
}

SDP::Core::processOptions();
	# Make sure that the process is actually running.  Then, check if process takes more than 1Gb.  If not, assume it takes > 1Mb
	SDP::eDir::eDirValidation(EDIR_NOT_RUNNING);

	my $mem = ndsd_memory_size();

	if ($mem == 0) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "ndsd not running");
	} elsif ($mem > 1048576) {
		my $mem_gb = $mem / 1024 / 1024 ;
		$mem_gb =~ m/(\d)\.(\d)/;
		if ($mem > 1887436) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "ndsd memory size is $1.$2 Gb");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "ndsd memory size is $1.$2 Gb");
		}
	} else {
		my $mem_mb = $mem / 1024 ;
		my $int = 0;
		($int) = split (/\./, $mem_mb);
		SDP::Core::updateStatus(STATUS_ERROR, "ndsd memory size $int Mb is less than 1Gb");
	}
SDP::Core::printPatternResults();

exit;

