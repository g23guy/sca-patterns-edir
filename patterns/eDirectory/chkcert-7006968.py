#!/usr/bin/python

# Title:       eDirectory Certificate Check
# Description: Checks for expired certificates
# Modified:    2014 Apr 02
#
##############################################################################
# Copyright (C) 2014 SUSE LLC
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

import sys, os, Core, SUSE, datetime

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "eDirectory"
META_CATEGORY = "Certificate"
META_COMPONENT = "Status"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7006968|META_LINK_TID2=http://www.novell.com/support/kb/doc.php?id=7003449|META_LINK_Video=https://elearning.novell.com/mod/scorm/loadSCO.php?id=18736&scoid=10825&mode=review|META_LINK_Master=https://www.novell.com/support/kb/doc.php?id=7003514"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

EXP_TOTAL = 0
EXP_THIRTY_DAYS = 1
EXP_EXPIRED = 2

##############################################################################
# Local Function Definitions
##############################################################################

def checkeDirCerts(CERTS):
	fileOpen = "novell-edir.txt"
	section = "objectclass=nDSPKIKeyMaterial"
	content = {}
	if Core.getSection(fileOpen, section, content):
		NOW = datetime.datetime.now()
#		print ("Now:     '%s'" % NOW)
		for line in content:
			if content[line].startswith("nDSPKINotAfter"):
				CERTS[EXP_TOTAL] += 1
				EXPIRES = content[line].split()[1]
				EX_YEAR = int(EXPIRES[0:4])
				EX_MONTH = int(EXPIRES[4:6])
				EX_DAY = int(EXPIRES[6:8])
				EX_HOUR = int(EXPIRES[8:10])
				EX_MIN = int(EXPIRES[10:12])
				EX_SEC = int(EXPIRES[12:])
				THEN = datetime.datetime(EX_YEAR, EX_MONTH, EX_DAY, EX_HOUR, EX_MIN, EX_SEC)
#				print ("Expires: '%s'" % THEN)
				DELTA = THEN - NOW
				DELTA30 = THEN - NOW - datetime.timedelta(days=30)
#				print "Delta = {0}, Delta 30 Days = {1}".format(DELTA.days, DELTA30.days)
				if( DELTA.days < 0 ):
					CERTS[EXP_EXPIRED] += 1
				elif( DELTA30.days < 0 ):
					CERTS[EXP_THIRTY_DAYS] += 1
#		print ("Certificates -- [Total, Expire30, Expired] : %s" % CERTS)
#	else:
#		print ("Certificates not found: %s" % CERTS)

##############################################################################
# Main Program Execution
##############################################################################

CERTS = [0, 0, 0]
checkeDirCerts(CERTS)
if( CERTS[EXP_TOTAL] > 0 ):
	if( CERTS[EXP_EXPIRED] > 0 ):
		Core.updateStatus(Core.CRIT, "Total: " + str(CERTS[EXP_TOTAL]) + ", Expired: " + str(CERTS[EXP_EXPIRED]) + ", Expire in 30 Days: " + str(CERTS[EXP_THIRTY_DAYS]))
	elif( CERTS[EXP_THIRTY_DAYS] > 0 ):
		Core.updateStatus(Core.WARN, "Total: " + str(CERTS[EXP_TOTAL]) + ", Expired: " + str(CERTS[EXP_EXPIRED]) + ", Expire in 30 Days: " + str(CERTS[EXP_THIRTY_DAYS]))
	else:
		Core.updateStatus(Core.IGNORE, "All certificates expire in more than thirty days")
else:
	Core.updateStatus(Core.ERROR, "Error: No eDirectory Certificates found")		

Core.printPatternResults()

