#!/usr/bin/perl -w

# Title:       Check for eDirectory core files
# Description: Check for any eDirectory core files, indicating a potential ndsd health problem.  Any number of cores will register as at least a warning.  Red status will be triggered for cores that are less than 7 days old.
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
#     Jason Record (jrecord@suse.com)
#     Tregaron Bayly (tbayly@novell.com)
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
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=eDirectory",
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=Core Files",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3078409"
);


##############################################################################
# Feature Subroutines
##############################################################################

sub core_files_found {
	printDebug(">", "core_files_found");
	my $FILE_SERVICE   = "novell-edir.txt";
	my $SECTION        = "ls -l";
	my @CONTENT        = ();
	my $RCODE          = 0;
	my $LINE           = 0;
        my $days           = 0;

	if ( SDP::Core::getSection($FILE_SERVICE, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			$LINE++;
			if ( /core/ ) {
                                my ($perms, $links, $owner, $group, $size, $month, $day, $yeartime, $filename) = split (/\s+/,$_);
				printDebug("LINE $LINE", $_); 
                                my $tmp_days = convert_date_parts_to_days($month, $day, $yeartime);
                                if ($tmp_days > $days) { $days = $tmp_days; }
                                printDebug(">", "$filename: $tmp_days : $days");
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_SERVICE");
	}
	printDebug(">", "core_files_found");
	return "$RCODE\t$days";
}

sub convert_date_parts_to_days {
  my ($month, $mday, $yeartime) = @_;

  if ($month eq "Jan") { $month = 0; }
  elsif ($month eq "Feb") { $month = 1; }
  elsif ($month eq "Mar") { $month = 2; }
  elsif ($month eq "Apr") { $month = 3; }
  elsif ($month eq "May") { $month = 4; }
  elsif ($month eq "Jun") { $month = 5; }
  elsif ($month eq "Jul") { $month = 6; }
  elsif ($month eq "Aug") { $month = 7; }
  elsif ($month eq "Sep") { $month = 8; }
  elsif ($month eq "Oct") { $month = 9; }
  elsif ($month eq "Nov") { $month = 10; }
  elsif ($month eq "Dec") { $month = 11; }
  else { SDP::Core::updateStatus(STATUS_ERROR, 'Unrecognized Month'); exit; } 

  if ($yeartime =~ m/:/) { $yeartime = "2009"; };

  my $days = _daygm( undef, undef, undef, $mday, $month, $yeartime );
  return $days;
  
}

sub _daygm {

    # Lifted this function from Time::Local library in order to 
    # not require that the perl installation have it included.
    # Copyright (c) 1997-2003 Graham Barr, 2003-2007 David Rolsky.  All
    # rights reserved.  This (module) is free software; you can redistribute
    # it and/or modify it under the same terms as Perl itself.
    #
    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
    return $_[3] + (
        do {
            my $month = ( $_[4] + 10 ) % 12;
            my $year  = ( $_[5] + 1900 ) - ( $month / 10 );

            ( ( 365 * $year )
              + ( $year / 4 )
              - ( $year / 100 )
              + ( $year / 400 )
              + ( ( ( $month * 306 ) + 5 ) / 10 )
            )
        }
    );
}

sub get_support_config_days {
   my @output = ();
   my $days = 0;   

   if (SDP::Core::getSection("basic-environment.txt", "/bin/date", \@output)) {
        my (undef, $month, $day, undef, undef, $year) = split (/\s+/, $output[0]);
        printDebug("Today is ", "$month $day, $year");
        $days = convert_date_parts_to_days($month, $day, $year);
   }
   else {
     SDP::Core::updateStatus(STATUS_ERROR, "Cannot find date section in basic-environment.txt");
   }

   return $days;

}

##############################################################################
# Main
##############################################################################

SDP::Core::processOptions();

	SDP::eDir::eDirValidation(EDIR_NOT_RUNNING);
	my ($cores,$core_days) = split(/\t/, core_files_found());
	my $sc_days = get_support_config_days();
	my $string = ($cores == 1 ? "$cores eDirectory core file found" : "$cores eDirectory core files found");

	if ($cores) {
		if ($sc_days - $core_days > 7) {
			SDP::Core::updateStatus(STATUS_WARNING, "$string, none in the last 7 days");
		} else {
			SDP::Core::updateStatus(STATUS_CRITICAL, "$string, at least one in the last 7 days");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No eDirectory core files found");
	}
SDP::Core::printPatternResults();

exit;


