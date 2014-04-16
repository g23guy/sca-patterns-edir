#!/usr/bin/perl -w

# Title:       Check persistent eDirectory cache settings
# Description: This pattern checks the _ndsdb.ini file for cache settings and makes recommendations based on the DIB size and Novell's performance testing.
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
use SDP::SUSE;
use SDP::eDir;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=Cache",
	PROPERTY_NAME_COMPONENT."=Config",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3178089"
);



##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	SDP::eDir::eDirValidation();

	my @output = ();
	my $section = "_ndsdb.ini";
	my $file = "novell-edir.txt";
	my $cachesize = 0;
	my $dibsize = 0;
	my $recommendation = 0;
	my $max_memory = SDP::eDir::ndsdMemoryMaximum();
	my $dynamic_adjust = 0;

	if ( SDP::Core::getSection($file, $section, \@output) ) {
		foreach $_ (@output) {
			if ( /^cache=/ ) {
				if (/DYN/ ) { # Customer has specified dynamic adjust
					$cachesize = 1;       # This will trigger a warning since it's less than 250MB, even though it's bogus
					$dynamic_adjust = 1;  # This flag will modify our message.
				} else { # Customer has specified a hard limit
					(undef, $cachesize) = split(/=/,$_);
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" section in $file");
	}

	@output = ();
	$section = "ls -l";
	$file = "novell-edir.txt";

	if ( SDP::Core::getSection($file, $section, \@output) ) {
		foreach $_ (@output) {
			if ( /nds/ ) {
				my (undef, undef, undef, undef, $filesize, undef, undef, undef, undef) = split(/\s+/, $_);
				$dibsize += $filesize;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" section in $file");
	}

	if ($cachesize) {
		my $message = "";
		my $upgrade_mem = 0;
		my $too_large = 0;
		$dibsize = int($dibsize / 1048576);
		if ($dibsize * 3 < 250) { $recommendation = 250; }
		elsif ($dibsize * 3 > 1024) { $recommendation = 1024; }
		else { $recommendation = $dibsize * 3; }

		$cachesize = int($cachesize / 1048576);
		if ($cachesize < 250 || $cachesize > 1024 || abs($cachesize - $recommendation) > 50) {
          # We are going to recommend a cache size change

            # Check to see if the recommendation exceeds 50% of the physical memory
            # If so, we will note that the server could use more physical memory
            # This will never be true for boxes that have more than twice the max recommended cache size (2 GB)
			@output = ();
			$section = "free";
			$file = "basic-health-check.txt";

			if ( SDP::Core::getSection($file, $section, \@output) ) {
				foreach $_ (@output) {
					if ( /Mem:/ ) {
						my (undef, $total, undef, undef, undef, undef, undef) = split(/\s+/, $_);
						$total = $total / 1024;
						$upgrade_mem = (($recommendation > ($total / 2)) ? 1 : 0 );
					}
				}
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" section in $file");
			}
            
			# If the recommendation is to increase the cache size, ensure that it won't push them into a max memory situation
			if ($recommendation > $cachesize) {
				@output = ();
				$section = "ps axwwo user,pid,ppid";
				$file = "basic-health-check.txt";
				my $max_ndsd_memory = SDP::eDir::ndsdMemoryMaximum();

				if ( SDP::Core::getSection($file, $section, \@output) ) {
					foreach $_ (@output) {
						if ( /ndsd/ ) {
							my (undef, undef, undef, undef, undef, $vsz, undef, undef, undef, undef) = split(/\s+/, $_);
							$vsz = $vsz / 1024;
							$too_large = (($vsz + $recommendation - $cachesize > $max_ndsd_memory * .9) ? 1 : 0 );
						}
					}
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$section\" section in $file");
				}
			}

			if ( $dynamic_adjust ) {
				$message = "Dynamic cache adjustment not recommended, suggest hard limit of $recommendation MB";
			} else {
				$message = "Cache size of $cachesize MB may not be optimal, suggest $recommendation MB";
			}

			if ($upgrade_mem) { $message = $message . " (may require upgrade of physical memory)"; }
			if ($too_large) { $message = "Cache size of $cachesize MB may not be optimal, but current ndsd memory size too large to increase cache to $recommendation MB"; } 

			SDP::Core::updateStatus(STATUS_RECOMMEND, $message);
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No cache size recommendations");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Did not find cache size setting in _ndsdb.ini file");
	}

SDP::Core::printPatternResults();

exit;

