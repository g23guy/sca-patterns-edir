#!/usr/bin/perl

# Title:       Check certificate expiration 
# Description: Determines how many certificates are associated with the server, the number that have expired and the number that will expire in the next 30 days. Currently, it's not possible to tell if any of the certificates are in use.  
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
#     Jim Schnitter (jschnitter@novell.com)
#     Jason Record (jrecord@suse.com)
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
	PROPERTY_NAME_CATEGORY."=Cert",
	PROPERTY_NAME_COMPONENT."=Status",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7003449"
);



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

sub check_certs() {

	my $FILE_SERVICE = "novell-edir.txt";
	my $SECTION = "objectclass=nDSPKIKeyMaterial";
	my @CONTENT = ();
	my @MYCONTENT = ();
	my $mycerts = 0;
	my $expired_certs = 0;
	my $expired_in_30 = 0;
	my $sc_days = get_support_config_days();
	my $line;
	my ($i, $year, $month, $day, $next_line);

        if ( SDP::Core::getSection($FILE_SERVICE, $SECTION, \@CONTENT) ) {
		printDebug("In check_certs:", "CONTENT is @CONTENT");

		# shift breaks down with blank lines. Need to strip them out
		foreach $i (@CONTENT) {
			if ($i ne '') {
				@MYCONTENT = (@MYCONTENT,$i);
			}
		}

                while ($line = shift @MYCONTENT) {
        	printDebug("In check_certs:", "line is $line");
		if ($line =~ m/^dn:/) {
			$mycerts++;

			# Assume next line contains the date
			$next_line = shift @MYCONTENT;
			if ($next_line =~ m/nDSPKINotAfter: (.{4})(.{2})(.{2})/) {
			$year = $1;
			$month = $2;
			$day = $3;
			# _daygm expects 0...11 for months
			$month--;

  			my $cert_days = _daygm( undef, undef, undef, $day, $month, $year);
			if ($cert_days - $sc_days < 0) {
				$expired_certs++;
			} elsif ($cert_days - $sc_days < 30) {
				$expired_in_30++;
			}
			} # end if on $next_line
		}
		} # end while 

	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_SERVICE");
        }
	
	return ($mycerts, $expired_certs, $expired_in_30);	
}

SDP::Core::processOptions();
	SDP::eDir::eDirValidation(EDIR_NOT_RUNNING);
	(my $num_certs, my $expired, my $num_thirty) = check_certs();

	if ($expired > 0 || $num_thirty > 0) {
		if ( $expired == $num_certs ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Total: $num_certs, Expired: $expired, Expires in 30 Days: $num_thirty");
		} else {
			SDP::Core::updateStatus(STATUS_WARNING, "Total: $num_certs, Expired: $expired, Expires in 30 Days: $num_thirty");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Total: $num_certs, Expired: $expired, Expires in 30 Days: $num_thirty");
	}
SDP::Core::printPatternResults();

exit;
