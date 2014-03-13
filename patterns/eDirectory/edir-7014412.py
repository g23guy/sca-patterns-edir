#!/usr/bin/python

# Title:       eDir install failure from SAS 603
# Description: Install of eDirectory fails with error 74 or error 78
# Modified:    2014 Jan 15
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

import sys, os, Core, SUSE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "eDirectory"
META_CATEGORY = "Install"
META_COMPONENT = "Security"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.novell.com/support/kb/doc.php?id=7014412|META_LINK_Video=https://www.youtube.com/watch?v=600DcXodxEM"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Local Function Definitions
##############################################################################

def sas603error():
	fileOpen = "y2log.txt"
	section1 = "/var/log/YaST2/y2log -"
	section2 = "/var/log/YaST2/y2log\n"
	content = {}
	if Core.getSection(fileOpen, section1, content):
		for line in content:
			if "Failed to configure SAS service" in content[line]:
				if "no such attribute err=-603" in content[line]:
					return True
	elif Core.getSection(fileOpen, section2, content):
		for line in content:
			if "Failed to configure SAS service" in content[line]:
				if "no such attribute err=-603" in content[line]:
					return True
	return False

def securityObject603error():
	fileOpen = "novell-edir.txt"
	section1 = "/ndsd.log -"
	section2 = "/ndsd.log\n"
	content = {}
	if Core.getSection(fileOpen, section1, content):
		for line in content:
			if "Error from pkiInstallCreatePKIObjects" in content[line]:
				if "= -603" in content[line]:
					return True
	elif Core.getSection(fileOpen, section2, content):
		for line in content:
			if "Error from pkiInstallCreatePKIObjects" in content[line]:
				if "= -603" in content[line]:
					return True
	return False

##############################################################################
# Main Program Execution
##############################################################################

if( sas603error() ):
	if( securityObject603error() ):
		Core.updateStatus(Core.CRIT, "Unable to contact the eDirectory CA, verify CA")
	else:
		Core.updateStatus(Core.WARN, "Potential eDirectory CA issue, verify CA")
else:
	if( securityObject603error() ):
		Core.updateStatus(Core.CRIT, "Unable to contact the eDirectory CA, verify CA")
	else:
		Core.updateStatus(Core.IGNORE, "No eDir SAS 603 detected")

Core.printPatternResults()


