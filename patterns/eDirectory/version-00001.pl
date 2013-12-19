#!/usr/bin/perl -w

# Title:       Check for eDirectory updates
# Description: This pattern compares the current version of eDirectory to the installed version and gives a digest of the fixes the installed version is missing.
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
#     Tregaron Bayly (tbayly@novell.com)
#     Mark Hinckley (mhinckley@novell.com)
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
	PROPERTY_NAME_CATEGORY."=Health",
	PROPERTY_NAME_COMPONENT."=Version",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3426981"
);




##############################################################################
# Feature Subroutines
##############################################################################


# There is 1 array here (populated by four functions by the oes/non-oes patching strategy in eDirectory 8.8, plus 8.7)
# eDir88_all:     all patches up to 882, plus 885 and beyond
# eDir88_oes:     884 patches, plus an oes-specific 882ftf
# eDir88_non_oes: 883 patches
# eDir87:         87 patches
#
# When counting fixes, 8.8 will verify the 88_all and either 88_oes or 88_non_oes arrays
# 8.7 will just verify the 87 array

# ============================================
# 8.8 All Versions
# ============================================
sub populate_88_all {
    my $eDir = $_[0];

push @$eDir, 
    ( { version  => '20601.18', 
        descr    => '8.8 SP6',
        cores    => '5',  # 545469 614674 598309 571827 591087
        security => '6',  # 572622 412890 540231 359754 507832 507264
        perform  => '21',  # 604830 576708 530637 243775 614674 545469 569561 512552 138913 138724 579479 556783 570293 615543 550241 593782 595635 550950 525695 505659 579537
        other    => '34',  # 629792 622336 614674 570269 564035 561280 542748 497822 301553 154457 612344 609838 592327 548067 532992 482161 540673 522900 179221 642504 484958 525696 229501 185172 138967 615543 578538 550400 515717 510438 564923 437241 601358 (XDAS tree name)
      });
	  
push @$eDir, 
    ( { version  => '20505.03', 
        descr    => '8.8 SP5 Patch 5',
        cores    => '3',  # 629101 597882 580984
        security => '0',  # 
        perform  => '7',  # 411049 592649 629079 608223 579479 579479 612271
        other    => '7',  # 521978 601564 601080 614732 617940 573801 605152
      });
	  
push @$eDir, 
    ( { version  => '20504.06', 
        descr    => '8.8 SP5 Patch 4',
        cores    => '4',  # 594799 581877 589787 530714
        security => '5',  # 571244 566651 588883 586854 540674
        perform  => '7',  # 566160 241501 595828 582538 576030/570489 536175 503523
        other    => '9',  # 587950 585070 570274 591392 578666  206379/429201/568768 525932 490647 527690/507887
      });
	  
 push @$eDir, 
    ( { version  => '20503.15', 
        descr    => '8.8 SP5 Patch 3',
        cores    => '5',  # 549540 544781 528062 531019 534249
        security => '2',  # 556624 548503 
        perform  => '3',  # 529692 537717 514433
        other    => '27', # 545582 527851 532719 535559 520108 520123 534991 537571 556774 557288 524120 511640 531892 548958 502981
                          # 506279 515907 521755 538752 542834 545126 208708 524010 530279 531313 534832 559787
      });

 push @$eDir, 
    ( { version  => '20502.05', 
        descr    => '8.8 SP5 Patch 2',
        cores    => '2',  # 488237 531468
        security => '2',  # 524344 544859 
        perform  => '2',  # 481856 302027
        other    => '22', # 415092 226615 510901 493527 532611 411806 476308 543471 495807 512609 489211 479047 482640 477423 7004358
                          # 537454 532825 516812 479536 124443 481359 481722
      });

 push @$eDir, 
    ( { version  => '20501.00', 
        descr    => '8.8 SP5 FTF1',
        cores    => '8',  # 508698 506033 514234 504016 497452 513041 512589 515056 
        security => '0',  # 
        perform  => '7',  # 497659 493121 492268 426644 505576 503350 497701
        other    => '29', # 495129 500676 507813 513827 518761 518484 509866 509866 340798 507345 516442 519968 490647 485116
                          # 500430 500431 505217 497943 519371 503785 485072 428669 489211 411806 526779 508096 481334 507130 503781
      });

 push @$eDir, 
    ( { version  => '20219.15', 
        descr    => '8.8 SP5',
        cores    => '13', # 493124 293386 448299 431770 434728 399188 474577 443689 459873 482586 441854 416690 455711
        security => '7',  # 449224 492692 458504 138797 158719 484007 446342
        perform  => '6',  # 465309 473956 431770 333648 488167 333648
        other    => '52', # 419539 470937 211999 386748 433529 456076 426219 395134 458171 434935 420243 411025 477053 344893
                          # 431670 455750 431502 486098 333648 468225 385792 470459 460252 346614 450485 417104 464204 457373
                          # 458195 475686 448493 476368 462461 459280 428664 409211 409123 327332 386901 481353 333648 395575
                          # 457694 335112 333648 426046 162441 468841 427186 464551 449042 434764
      });  

  push @$eDir, 
    ( { version  => '20114.24', 
        descr    => '8.8 SP1',
        cores    => '8',  # 138700 138980 138707 140469 139077 138722 138678 145221
        security => '2',  # 176297 172105
        perform  => '7',  # 167938 138681 136705 139171 139033 138897 138721
        other    => '41', # 138738 138720 138670 138732 159356 153018 147246 139063 147595 138694 141186 151321 151345 151303
                          # 151294 170158 157869 139120 138701 138156  83100 132334 138673 139107 138687 138679 138683 138698
                          # 138690 169030 144448 140482 138717 176278 154224 149595 145590 138728 144992 143930 141013 
      });  

  push @$eDir, 
    ( { version  => '20114.28', 
        descr    => '8.8 SP1 FTF1',
        cores    => '1',  # 187986
        security => '1',  # 195511
        perform  => '0',  # 
        other    => '4',  # 182127 181124 203231 177366
      }); 

  push @$eDir, 
    ( { version  => '20114.29', # This is the same binary version as SP2!
        descr    => '8.8 SP1 FTF2',
        cores    => '3',  # 195523 203955 173812
        security => '2',  # 195510 200535
        perform  => '0',  # 
        other    => '6',  # 216834 206656 206656 181124 222775 201775
      });

  push @$eDir, 
    ( { version  => '20216.51', 
        descr    => '8.8 SP2',
        cores    => '4',  # 262355 187986 249867 209965
        security => '4',  # 176635 204086 172109 203955
        perform  => '10', # 171544 151774 149385 195018 176629 280662 189221 169576 145082 165259
        other    => '62', # 180159 232928 183787 198750 174942 174242 160047 162814 158949 157848 175625 239738 174258 201090
                          # 176260 156032 290819 284607 179275 164429 196211 213212 172107 197100 278123 218704 208288 217733
                          # 191507 187768 281899 196883 155743 174794 175630 195052 286174 146168 201775 165781 216834 237886
                          # 187140 191522 175929 267278 273084 222775 201847 194426 263326 281116 203231 231473 211082 179251
                          # 243226 196784 162934 166169 199595 251239
      });

  push @$eDir, 
    ( { version  => '20216.59', # OES is .60 and the linux-only is .59
        descr    => '8.8 SP2 FTF1',
        cores    => '6',  # 326830 327990 329207 290318 328394 329802
        security => '1',  # 309580
        perform  => '1',  # 346181 
        other    => '10', # 344871 335277 339721 336377 332801 338569 335227 272056 215603 337432
      });

  push @$eDir, 
    ( { version  => '20216.62',
        descr    => '8.8 SP2 FTF2',
        cores    => '3',  # 356840 358919 360025
        security => '5',  # 373853 368832 306096 353004 373853
        perform  => '4',  # 367596 265992 357473 333244
        other    => '15', # 291853 378136 329091 306741 301811 359077 357815 301553 364036 354165 207182 357872 334627 340156
                          # 364902
      });
}
# ============================================
# 8.8 OES-only patches
# ============================================
sub populate_88_oes_only {
  my $eDir = $_[0];
  push @$eDir, 
    ( { version  => '20216.63',
        descr    => '8.8 SP2 FTF3',
        cores    => '0',
        security => '6',  # 387429 373852 396819 396817 379882 379880
        perform  => '0',
        other    => '0',
      });

  push @$eDir,
    ( { version  => '20217.06',
        descr    => '8.8 SP4',
        cores    => '3',  # 417311 394957 444943
        security => '1',  # 371653
        perform  => '6',  # 403278 288843 434862 296389 243774 408004
        other    => '33',  # 403301 412890 343753 301437 427317 264544 412286 439921 391935 391934 421299 390950 154431 417578 412045      
                          # 411873 408602 158982 303696 305175 137351 416052 307559 329707 329707 392326 354720 300977 285829 145729
                          # 145727 164690 142381
      });

  push @$eDir,
    ( { version  => '20217.07',
        descr    => '8.8 SP4 FTF1',
        cores    => '6',  # 416690 399188 344893 431783 393474 434728
        security => '2',  # 446342 449224
        perform  => '2',  # 431489 465309
        other    => '9',  # 417104 450485 431502 458504 459276 456076 343753 419539 455750
      });

}
# ============================================
# 8.8 Non-OES-only patches
# ============================================
sub populate_88_non_oes {
  my $eDir = $_[0];
  push @$eDir, 
    ( { version  => '20216.83',
        descr    => '8.8 SP3',
        cores    => '3',  # 372984 371685 368323
        security => '7',  # 171477 379880 379882 387429 373853 272056 396819
        perform  => '5',  # 288370 296276 296747 356413 379559
        other    => '44', # 363907 291524 338794 364333 347332 353045 359754 370129 337768 410171 397443 403358 329512 329515
                          # 376043 373480 389675 389904 326955 335227 339673 378851 381773 357766 365347 335277 307180 334627
                          # 378136 385838 138763 215603 220868 293273 296276 347328 359077 406041 378424 376047 336377 346181
                          # 377121 378635
      });

  push @$eDir, 
    ( { version  => '20216.87',
        descr    => '8.8 SP3 FTF2',
        cores    => '4',  # 411425 349954 403864 417619
        security => '2',  # 288797 396819
        perform  => '3',  # 417236 414846 403278
        other    => '9',  # 411721 307559 406016 426349 412766 420389 415269 433529 410976
      });

  push @$eDir, 
    ( { version  => '20216.89',
        descr    => '8.8 SP3 FTF3',
        cores    => '7',  # 416690 399188 344893 431783 393474 458504 434728
        security => '1',  # 449224
        perform  => '3',  # 431489 465309 413580
        other    => '10', # 455750 467858 417104 450485 431502 437795 459276 456076 343753 419539
      });
}
# ============================================
# 8.7 patches
# ============================================
sub populate_87 {
  my $eDir = $_[0];

  push @$eDir, 
    ( { version  => '10553.37',
        descr    => '8.7.3 SP8',
        cores    => '8',  # 102281 119284 145062 148510 149960 131178 128517 140239
        security => '0',
        perform  => '6',  # 129666 135793  95274 142943 147813 115733
        other    => '30', #  98632 100613 114165 131572 134514 134702 142020 143434 150633 106082 128327 114423 117512 147112  83029
                          #  86777  94515 104847 113990 118254 151048  84806 115364 117532 140761 144198 146780 115660 140888 154330
      });

  push @$eDir, 
    ( { version  => '10554.44',
        descr    => '8.7.3 SP10 FTF1',
        cores    => '5',  # 406276 386048 404308 408973 410620
        security => '4',  # 407275 407256 407243 407245
        perform  => '2',  # 400753 412688 
        other    => '11', # 412974 387627 411438 385350 391267 380515 380574 380574 386562 401310 384978
      });

  push @$eDir, 
    ( { version  => '10554.34',
        descr    => '8.7.3 SP10a',
        cores    => '2',  # 368835 373853
        security => '1',  # 357369
        perform  => '0',  # 
        other    => '5',  # 379917 378880 378905 379917 378165
      });

  push @$eDir, 
    ( { version  => '10554.31',
        descr    => '8.7.3 SP10',
        cores    => '6',  # 351137 341016 333536 306094 294716 365330
        security => '2',  # 288785 297065
        perform  => '4',  # 336116 265992 330806 290819 
        other    => '28', # 355844 290649 158683 190796 151294 343464 306741 346868 309630 207182 339721 330475 300233 248572 242156
                          # 343214  32800 238114 261480 266341 254990 274556 262677 290624 252965 363925 342621 222006
      }); 

  push @$eDir, 
    ( { version  => '10553.93',
        descr    => '8.7.3 SP9 FTF3',
        cores    => '1',  # 294209
        security => '1',  # 290811
        perform  => '4',  # 241654 264599 280573 245354
        other    => '10', # 291853 232757 228713 160130 276314 283188 277128 241654 284604 281457
      }); 

  push @$eDir, 
    ( { version  => '10553.85',
        descr    => '8.7.3 SP9 FTF2',
        cores    => '3',  # 268645 231549 219722
        security => '1',  # 228713 
        perform  => '0',  # 
        other    => '16', # 221722 251976 235500 220868 272192 219386 271308 208645 180412 263071 269584 231606 233656 250894 248218
                          # 248226
      }); 

  push @$eDir, 
    ( { version  => '10553.79',
        descr    => '8.7.3 SP9 FTF1',
        cores    => '2',  # 214750 222393
        security => '2',  # 204445 195510
        perform  => '3',  # 224203 228005 215517 
        other    => '10',  # 215906 219380 223410 216686 157855 203780 216728 203865 140888 232333 
      }); 

  push @$eDir, 
    ( { version  => '10553.69',
        descr    => '8.7.3 SP9',
        cores    => '5',  #  83020 156428 203180 191182 205042 
        security => '7',  # 197627 197629 197711 156683  93995 205313  83008
        perform  => '3',  # 192595  83042 142769 
        other    => '19', #  97104 155652 158565 176696  94515 155554 162974 169806 170841 177174 168102 186311 207153 122521 200329
                          # 156011 151067 208663 208964
      }); 


}


##############################################################################
# Main
##############################################################################

SDP::Core::processOptions();

        SDP::eDir::eDirValidation();
        my %ndsstat = SDP::eDir::eDirStatus();
        my @eDir = ();
        my $is_oes = 0;

        #Based on information found, populate arrays
        if ($ndsstat{'Product Version'} =~ "8.7") {
          populate_87(\@eDir);
        }
        elsif ($ndsstat{'Product Version'} =~ "8.8") {
          populate_88_all(\@eDir);
            my $file = "basic-environment.txt";
            my $section = "/etc/novell-release";
            my @output = ();

          if (SDP::Core::getSection($file, $section, \@output)) {
            foreach $_ (@output) {
              if ($_ =~ "Open Enterprise Server") { $is_oes = 1; }
            }
          }
          if ($is_oes) { populate_88_oes_only(\@eDir); }
          else { populate_88_non_oes(\@eDir); }
        }

        my $cores = 0;
        my $security = 0;
        my $perform = 0;
        my $other = 0;
        my $latest_string = "";
        my $latest_binary = 0;
 
        for (my $i = 0; $i <= $#eDir; $i++) {
          if ($eDir[$i]{'version'} > $ndsstat{'Binary Version'}) {
            $cores += $eDir[$i]{'cores'};
            $security += $eDir[$i]{'security'};
            $perform += $eDir[$i]{'perform'};
            $other += $eDir[$i]{'other'};
            if ($eDir[$i]{'version'} > $latest_binary) {
              $latest_binary = $eDir[$i]{'version'};
              $latest_string = $eDir[$i]{'descr'};
            }
          }
        }
        
	if ($latest_binary) {
		SDP::Core::updateStatus(STATUS_WARNING, "Update to $latest_string to get $cores crash, $security security, $perform performance and $other other fixes");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No udpates needed");
	}

SDP::Core::printPatternResults();

exit;

