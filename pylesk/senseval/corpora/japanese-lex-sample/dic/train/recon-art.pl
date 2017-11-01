#!/usr/local/bin/perl

#########################################################################
# Copyright (C) 2001
#			Tokunaga Takenobu
#			Department of Computer Science
#			Tokyo Institute of Technolgy
#			take@cl.cs.titech.ac.jp
#
#			Shirai Kiyoaki
#			School of Information Science,
#			Japan Advanced Institute of Science and Technology
#			kshirai@jaist.ac.jp
#
# Permission to use, copy, modify and distribute this software is
# granted only for non-commercial purposes. Any copy or derived version
# should include this copyright notice. Fees for distribution or use of
# this software or derived version may only be charged with the written
# permission of the copyright holder.  This software is provided AS IS
# without express or implied warranty.
#########################################################################
#
##########################################################
# IMPORTANT: This file should be saved in Shift-JIS code #
##########################################################

# suffixes
#
$Suf_idx = "idx"; # Index file, article no. -> offset,size (Article file)
$Suf_dif = "dif"; # Diff. file, morpheme records (length and POS code)
$Suf_ix1 = "ix1"; # Index file, article no. -> offset,size (Diff. file)
$Suf_ix2 = "ix2"; # $suf_ix1: headline, $suf_ix2: article body

# get options and show help if necessary
#
require "getopts.pl";
if(! &Getopts('hD:F:I:et') || $opt_h){
    &usage;
    exit;
}

die "cannot use both -e and -t\n" if $opt_e && $opt_t;
if($opt_e){
  $data_type = 'eval';
}elsif($opt_t){
  $data_type = 'train';
}else{
  $data_type = 'eval';	# default
}

$tag_type = 0;

# set index directory
#
if ($opt_D) {
    $IndexDir = $opt_D;
}
elsif ($ENV{MAINITI_INDEX_DIR}) {
    $IndexDir = $ENV{MAINITI_INDEX_DIR};
}
else {
    die "$0: index directory not specified.\n";
}

# base filename of index files
#
if ($opt_I) {
    $FileName = $opt_I;
}
else {
    $FileName = "mai";		# Default
}

# make full path filenames
#
$Fullpath_idx = "$IndexDir/$FileName.$Suf_idx";
$Fullpath_dif = "$IndexDir/$FileName.$Suf_dif";
$Fullpath_ix1 = "$IndexDir/$FileName.$Suf_ix1";
$Fullpath_ix2 = "$IndexDir/$FileName.$Suf_ix2";

# mapping table from 2 byte chars to 1 byte chars
#
# old tag set (91-93)
#
$ZtoH{"ÇhÇc"}     = "ID";
$ZtoH{"Ç`ÇcÇc"}   = "ADD";
$ZtoH{"Ç`Çd"}     = "AE";
$ZtoH{"Ç`Çe"}     = "AF";
$ZtoH{"ÇcÇs"}     = "DT";
$ZtoH{"ÇoÇf"}     = "PG";
$ZtoH{"ÇyÇt"}     = "ZU";
$ZtoH{"ÇlÇd"}     = "ME";
$ZtoH{"ÇsÇhÇm"}   = "TIN";
$ZtoH{"ÇsÇh"}     = "TI";
$ZtoH{"ÇpÇsÇh"}   = "QTI";
$ZtoH{"ÇsÇhÇj"}   = "TIK";
$ZtoH{"ÇpÇsÇhÇj"} = "QTIK";
$ZtoH{"ÇgÇnÇm"}   = "HON";
$ZtoH{"ÇgÇnÇP"}   = "HO1";
$ZtoH{"ÇpÇgÇnÇP"} = "QHO1";
$ZtoH{"ÇgÇjÇP"}   = "HK1";
$ZtoH{"ÇpÇgÇjÇP"} = "QHK1";
$ZtoH{"ÇbÇe"}     = "CF";
#
# new tag set (94-); some tags are common with old one
#
$ZtoH{"Ç`Ç`"}     = "AA";
$ZtoH{"ÇjÇ`"}     = "KA";
$ZtoH{"Ç`Ça"}     = "AB";
$ZtoH{"ÇjÇa"}     = "KB";
$ZtoH{"Ç`Çc"}     = "AD";
$ZtoH{"ÇbÇO"}     = "C0";
$ZtoH{"ÇsÇP"}     = "T1";
$ZtoH{"ÇrÇP"}     = "S1";
$ZtoH{"ÇrÇQ"}     = "S2";
$ZtoH{"ÇsÇQ"}     = "T2";
$ZtoH{"ÇyÇy"}     = "ZZ";

# set the data file path
#
if ($opt_F) {
    $DataPath = $opt_F;
} elsif ($ENV{MAINITI_DATA_PATH}) {
    $DataPath = $ENV{MAINITI_DATA_PATH};
} else {
    die "$0: data path not specified.\n";
}

# defalut setting of field switch (1:show, 0:hide)
#
# old tag set (91-93)
#
$FSW{"ID"}   = 1; # Identifier (unique)
$FSW{"ADD"}  = 0; # article no. (unique)
$FSW{"AE"}   = 0; # date & page
$FSW{"AF"}   = 0; # index article no.
$FSW{"DT"}   = 0; # date
$FSW{"PG"}   = 0; # page
$FSW{"ZU"}   = 0; # has figure?
$FSW{"ME"}   = 0; # article category
$FSW{"TIN"}  = 0; # headline
$FSW{"TI"}   = 0; # headline keyword in Kana  (by Mainiti)
$FSW{"QTI"}  = 0; # headline keyword in Kana  (by Nitigai assoc.)
$FSW{"TIK"}  = 0; # headline keyword in Kanzi (by Mainiti)
$FSW{"QTIK"} = 0; # headline keyword in Kanzi (by Nitigai assoc.)
$FSW{"HON"}  = 0; # article body
$FSW{"HO1"}  = 0; # keyword in Kana (by Mainiti)
$FSW{"QHO1"} = 0; # keyword in Kana (by Nitigai assoc.)
$FSW{"HK1"}  = 0; # keyword in Kanzi (by Mainiti)
$FSW{"QHK1"} = 0; # keyword in Kanzi (by Nitigai assoc.)
$FSW{"CF"}   = 0; # copyright flag
#
# new tag set (94-)
# ID, AE, AF are common with Old tag set but may have different meaning
#
$FSW{"AA"}   = 0; # headline keyword in Kana
$FSW{"KA"}   = 0; # headline keyword in Kanzi
$FSW{"AB"}   = 0; # keyword in Kana
$FSW{"KB"}   = 0; # keyword in Kanzi
$FSW{"AD"}   = 0; # article category
$FSW{"C0"}   = 0; # index article no. 
$FSW{"T1"}   = 2; # headline
$FSW{"S1"}   = 0; # date/paper type/page/has figure?/char. count
$FSW{"S2"}   = 0; # the first paragraph of the article body
$FSW{"T2"}   = 2; # article body
$FSW{"ZZ"}   = 0; # copyright flag

# open data file
#
open(DAT, $DataPath) || die "$0: fail to open $DataPath\n";

# open morphological analysis files if necessary
#
if ($FSW{"T1"} > 1 || $FSW{"T2"} > 1 || $FSW{"TIN"} > 1 || $FSW{"HON"} > 1) {
    open(MORDIF,"$Fullpath_dif") || die "$0: fail to open $Fullpath_dif";
    while(<MORDIF>){		# Read POS code table
#	chop;
	s/\s$//o;
	($pos_id, @pos) = split(/\t/);
	if($pos_id){		# if terminator? (terminator = 0)
	    $POS{$pos_id} = join("\t",@pos);
	}
	else{
	    last;		# end of POS code table
	}
    }
    if ($FSW{"T1"} > 1 || $FSW{"TIN"} > 1) {
	open(MORIX1, "$Fullpath_ix1") ||
	    die "$0: fail to open $Fullpath_ix1\n";
    }
    if ($FSW{"T2"} > 1 || $FSW{"HON"} > 1) {
	open(MORIX2, "$Fullpath_ix2") ||
	    die "$0: fail to open $Fullpath_ix2\n";
    }
}

# read and print
#

open(IDX, "$Fullpath_idx") || die "$0: fail to open $Fullpath_idx\n";
if($data_type eq 'eval'){
  foreach (@eval_article_list){
    &Read_Article($_);
  };
}else{
  foreach (1..3000){
    &Read_Article($_);
  };
};    
close(IDX);

###############
# Subroutines #
###############

# given an article no., read the article and print it 
#
sub Read_Article {
    local ($seq) = @_;
    local ($buffer, $offset, $size);
    
    seek(IDX, ($seq-1)*6, 0) || die "$0: seek error in index file\n";
    read(IDX, $buffer,    6) || die "$0: read error in index file\n";
#
#    ($offset, $size) = unpack("N n", $buffer);
#
# AlphaÇÃ"N"ÇÕ8ÉoÉCÉgÇÁÇµÇ≠Ç±ÇÃÇ‹Ç‹Ç∂Ç·Ç§Ç‹Ç≠ìÆÇ©Ç»Ç¢
# à»â∫ÇÕquick hack 
# by Tokunaga 97/5/19
#
    ($Hoff, $Loff, $size) = unpack("n n n", $buffer);
    $offset = 65536*$Hoff + $Loff;
    seek(DAT, $offset, 0)     || die "$0: seek error in data file\n";
    read(DAT, $buffer, $size) || die "$0: read error in data file\n";

    &Format_Article($buffer, $seq);
}

# format an article as specified in the options
#
sub Format_Article {
    local ($buffer, $seq) = @_;
    local ($l, $tag, $field);

    undef(@Morph_List);		# @Morph_List is grobal var.
    chop($buffer); # delete last \n
    $result =~ s/\n$//o;
    foreach $l (split(/\n/, $buffer)) {	# divide into lines
	# modified by Shirai (2000/3/14)
	$l =~ /^Å_(.+)Å_(.*)$/;	# separate tag and its value
	$tag = $ZtoH{$1};
	$field = $2;

	if ($FSW{$tag}) {	# print this field ?
	    if ($FSW{$tag} > 1) { # morphological analysis is required?
		$field = &Do_Morph_Analysis($tag, $field);
		if ($tag_type == 0) {
		    $field = "\n" . $field;
		}
	    }
	    if ($tag_type == 0) {	# which tag style?
		print "Å_$1Å_";
	    }
	    elsif ($tag_type == 2) {
		print "<$tag>\n";
	    }
	    print "$field\n";
	    if ($tag_type == 2) {
		print "</$tag>\n";
	    }
	}
    }
}

# divide the field into  morphemes
#
sub Do_Morph_Analysis{
    local($tag, $text) = @_;
    local($buffer, $offset, $size);
    local($idx, $morph, $pos, $len, $real_len, $result, $prev_pos);

    # get morph record list in @Morph_List
    # note that @Morph_List should be static (grobal)
    # when analyzing article body
    #
    if ($tag eq "T1" || $tag eq "TIN") {
	seek(MORIX1, ($seq-1)*6, 0) || die "$0: seek error in $Fullpath_ix1\n";
	read(MORIX1, $buffer,    6) || die "$0: read error in $Fullpath_ix1\n";
#	($offset, $size) = unpack("N n", $buffer); 
# quick hack for Alpha. See above
#
	($Hoff, $Loff, $size) = unpack("n n n", $buffer);
	$offset = 65536*$Hoff + $Loff;
	seek(MORDIF, $offset, 0)       || die "seek error in $Fullpath_dif\n";
	read(MORDIF, $buffer, $size*2) || die "read error in $Fullpath_dif\n";
	@Morph_List = unpack("n*", $buffer);
    }
    elsif (!defined(@Morph_List)) { # $tag == "T2" or "HON"
	seek(MORIX2, ($seq-1)*6, 0) || die "$0: seek error in $Fullpath_ix2\n";
	read(MORIX2, $buffer,    6) || die "$0: read error in $Fullpath_ix2\n";
#	($offset, $size) = unpack("N n", $buffer); #
# quick hack for Alpha. See above
#
	($Hoff, $Loff, $size) = unpack("n n n", $buffer);
	$offset = 65536*$Hoff + $Loff;
	seek(MORDIF, $offset, 0)       || die "seek error in $Fullpath_dif\n";
	read(MORDIF, $buffer, $size*2) || die "read error in $Fullpath_dif\n";
	@Morph_List = unpack("n*", $buffer);
    }

    $idx = 0;
    $result = "";
    $prev_pos = "";
    while ($idx < length($text)) {
	$real_len = 0;
	$morph = shift(@Morph_List);
	$pos = 0x03ff & $morph;
	$len = $morph >> 10;
	if ($len == 0) {
	    $real_len = 63 * $pos;
	    $morph = shift(@Morph_List);
	    $pos = 0x03ff & $morph;
	    $len = $morph >> 10;
	}
	$real_len += $len;

	$morph = substr($text, $idx, $real_len * 2);
	$result .= $morph . "\t";
	$result .= &GetBaseform($morph, $pos, $prev_pos) . "\t";
	$result .= ($FSW{$tag} == 2 && $POS{$pos}) ? $pos : $POS{$pos};
	$result .= "\n";

	$idx += $real_len * 2;
	$prev_pos = $pos;
    }
#    chop($result);		# delete last \n
    $result =~ s/\n$//o;

    if ($tag eq "T1" || $tag eq "TIN") {
	undef(@Morph_List);
    }
    return($result);
}

sub GetBaseform{
    local($morph,$pos,$prev_pos)=@_;
    local($head,$inst,$d_inst,$c_inst);

    # getting instruction
    $inst = $pos2inst[$pos];

    # do nothing
    if($inst eq 'fi' || $inst eq 'no' || $inst eq 'un'){
	return($morph);

    # replaceing rule
    }elsif($inst eq 'r1'){
	$head = substr($morph,0,2);
	if($head eq 'ÇΩ'){
	    return('ÇΩ');
	}elsif($head eq 'Ç‹'){
	    return('Ç‹Ç∑');
	}elsif($head eq 'Ç ' || $head eq 'Ç∏' ||
	       $head eq 'Ç¥' || $head eq 'ÇÀ'){
	    return('Ç ');
	}elsif($head eq 'Ç…' || $head eq 'Ç»'){
	    return('Çæ');
	}elsif($head eq 'Ç≈'){
	    if( length($morph) == 2 ){
		return('Çæ');
	    }else{
		return('Ç≈Ç∑');
	    };
	}elsif($head eq 'Çæ'){
	    if( substr($morph,2,2) eq 'Ç¡' ){
		return('Çæ');
	    }elsif($prev_pos == 182 || $prev_pos == 226 ||
		   $prev_pos == 237 || $prev_pos == 248 ||
		   $prev_pos == 259){
		return('ÇΩ');
	    }else{
		return('Çæ');
	    };
	}else{
#	    print STDERR "converting error: `$inst'`$morph'`$pos'\n";
#	    return('Åñ');
	    die("converting error: `$inst'`$morph'`$pos'");
	};
    }elsif($inst eq 'r2'){
	$head = substr($morph,0,2);
	if($head eq 'Ç≤'){
	    return('Ç≤Ç∆Çµ');
	}elsif($head eq 'Ç∂'){
	    return('Ç∂');
	}elsif($head eq 'ÇΩ'){
	    return('ÇΩÇË');
	}elsif($head eq 'Ç»'){
	    return('Ç»ÇË');
	}elsif($head eq 'Ç◊'){
	    return('Ç◊Çµ');
	}elsif($head eq 'Ç‹'){
	    return('Ç‹Ç∂');
	}elsif($head eq 'ÇØ'){
	    return('ÇØÇË');
	}elsif($head eq 'î@'){
	    return('î@Çµ');
	}elsif($head eq 'Ç´'){
	    return('Ç´');
	}elsif($head eq 'Çµ'){
	    return('Ç´');
	}elsif($head eq 'ÇË'){
	    return('ÇË');
	}elsif($head eq 'Éä'){
	    return('Éä');
	}elsif($head eq 'ÇÁ'){
	    if( length($morph) == 2 ){
		return('ÇË');
	    }else{
		return('ÇÁÇÈ');
	    };
	}elsif($head eq 'ÇÈ'){
	    if( length($morph) == 2 ){
		if($pos == 463){
		    return('ÇÈ');
		}elsif($pos == 464){
		    return('ÇË');
		}else{
#		    print STDERR "converting error: `$inst'`$morph'`$pos'\n";
#		    return('Åñ');
		    die("converting error: `$inst'`$morph'`$pos'");
		};
	    }else{
		return('ÇÈ');
	    };
	}elsif($head eq 'ÇÍ'){
	    if( length($morph) == 2 ){
		return('ÇË');
	    }else{
		return('ÇÈ');
	    };
	}else{
#	    print STDERR "converting error: `$inst'`$morph'`$pos'\n";
#	    return('Åñ');
	    die("converting error: `$inst'`$morph'`$pos'");
	};

    }elsif($inst eq 'r3'){
	$head = substr($morph,0,2);
	if($head eq 'Ç≈'){
	    return('Çƒ');
	}else{
	    return($morph);
	};

    # deletion and addition rule
    }else{
	($d_inst,$c_inst) = split(':',$inst);

	# deletion
	if($d_inst =~ /^d([123])$/o){
	    $morph = substr($morph, 0, length($morph)-2*$1);
	}elsif($d_inst eq 's1'){
	    if( substr($morph,-2) ne 'óà' ){
		$morph = substr($morph, 0, length($morph)-2);
	    };
	}elsif($d_inst eq 's2'){
	    if( substr($morph,-4, 2) eq 'óà' ){
		$morph = substr($morph, 0, length($morph)-2);
	    }else{
		$morph = substr($morph, 0, length($morph)-4);
	    };
	}elsif($d_inst eq 'nl'){	# do not delete
	    ;
	}else{
#	    print STDERR "converting error: `$inst'`$morph'`$pos'\n";
#	    return('Åñ');
	    die("converting error: `$inst'`$morph'`$pos'");
	};

	# addition
	if($c_inst eq 'bu'){
	    return( $morph . 'Ç‘' );
	}elsif($c_inst eq 'gu'){
	    return( $morph . 'ÇÆ' );
	}elsif($c_inst eq 'ku'){
	    return( $morph . 'Ç≠' );
	}elsif($c_inst eq 'mu'){
	    return( $morph . 'Çﬁ' );
	}elsif($c_inst eq 'nu'){
	    return( $morph . 'Ç ' );
	}elsif($c_inst eq 'ru'){
	    return( $morph . 'ÇÈ' );
	}elsif($c_inst eq 'sr'){
	    return( $morph . 'Ç∑ÇÈ' );
	}elsif($c_inst eq 'su'){
	    return( $morph . 'Ç∑' );
	}elsif($c_inst eq 'tu'){
	    return( $morph . 'Ç¬' );
	}elsif($c_inst eq 'wu'){
	    return( $morph . 'Ç§' );
	}elsif($c_inst eq 'yi'){
	    return( $morph . 'Ç¢' );
	}elsif($c_inst eq 'zr'){
	    return( $morph . 'Ç∏ÇÈ' );
	}elsif($c_inst eq 'sp'){
	    if( substr($morph,-2) eq 'óà' ){
		return( $morph . 'ÇÈ' );
	    }else{
		return( $morph . 'Ç≠ÇÈ' );
	    };
	}else{
#	    print STDERR "converting error:  `$inst'`$morph'`$pos'\n";
#	    return( 'Åñ' );
	    die("converting error: `$inst'`$morph'`$pos'");
	};
    };
};

sub usage {
    print <<"USAGE";
usage: $0 [option ...]
  -D <dir>	index file directory
  -I <name>	index file base name
  -F <file>	data file path
  -e		reconstruction of evaluation text
  -t		reconstruction of training text

  -h		show help
USAGE
}

BEGIN {

@eval_article_list = (
    1,    2,    4,    6,    9,   12,   13,   18,   21,   31,   33,   34,
   35,   47,   50,   55,   71,   79,   80,   83,   85,   90,   94,  113,
  116,  118,  119,  121,  123,  126,  127,  128,  135,  136,  143,  145,
  159,  160,  163,  176,  178,  181,  182,  190,  192,  195,  196,  202,
  208,  226,  235,  238,  241,  244,  252,  253,  254,  256,  258,  268,
  272,  283,  293,  295,  298,  301,  304,  310,  315,  316,  317,  333,
  338,  342,  346,  347,  348,  350,  354,  358,  374,  380,  381,  382,
  385,  386,  388,  392,  398,  399,  401,  413,  415,  417,  418,  419,
  429,  430,  432,  435,  438,  439,  440,  444,  446,  448,  449,  455,
  457,  459,  462,  463,  467,  469,  471,  473,  476,  486,  488,  494,
  496,  506,  508,  510,  513,  522,  523,  531,  534,  548,  552,  553,
  569,  576,  577,  580,  587,  592,  602,  605,  613,  614,  615,  621,
  622,  623,  626,  632,  633,  634,  638,  639,  644,  645,  653,  658,
  660,  662,  667,  670,  673,  675,  677,  678,  684,  690,  692,  694,
  701,  706,  707,  712,  717,  718,  720,  723,  725,  727,  728,  731,
  740,  741,  745,  749,  750,  753,  754,  755,  760,  761,  765,  767,
  778,  779,  785,  793,  796,  803,  807,  809,  810,  813,  839,  849,
  852,  853,  855,  861,  862,  865,  874,  883,  885,  886,  892,  893,
  896,  903,  905,  907,  908,  919,  920,  922,  924,  935,  936,  937,
  938,  951,  952,  953,  954,  968,  969,  972,  973,  977,  978,  979,
  982,  983,  996,  997, 1003, 1007, 1008, 1011, 1018, 1019, 1020, 1021,
 1024, 1027, 1029, 1035, 1046, 1047, 1049, 1056, 1066, 1067, 1073, 1074,
 1086, 1087, 1090, 1091, 1098, 1103, 1105, 1111, 1112, 1114, 1126, 1127,
 1129, 1138, 1141, 1144, 1150, 1151, 1153, 1154, 1165, 1172, 1178, 1180,
 1181, 1183, 1193, 1195, 1200, 1202, 1208, 1210, 1212, 1214, 1216, 1226,
 1229, 1232, 1233, 1236, 1238, 1239, 1241, 1248, 1254, 1255, 1259, 1260,
 1269, 1270, 1274, 1277, 1281, 1283, 1287, 1293, 1302, 1313, 1315, 1316,
 1329, 1331, 1337, 1340, 1343, 1347, 1366, 1367, 1369, 1372, 1374, 1381,
 1388, 1389, 1391, 1395, 1396, 1397, 1398, 1404, 1406, 1407, 1411, 1416,
 1418, 1421, 1428, 1435, 1436, 1445, 1446, 1453, 1454, 1465, 1466, 1468,
 1477, 1495, 1497, 1500, 1501, 1507, 1518, 1525, 1527, 1532, 1536, 1538,
 1539, 1540, 1542, 1546, 1550, 1559, 1562, 1567, 1569, 1571, 1572, 1574,
 1575, 1576, 1585, 1587, 1588, 1594, 1597, 1599, 1602, 1604, 1607, 1608,
 1609, 1623, 1624, 1636, 1641, 1642, 1650, 1672, 1679, 1681, 1682, 1690,
 1696, 1705, 1707, 1721, 1723, 1732, 1736, 1737, 1744, 1746, 1749, 1757,
 1758, 1761, 1769, 1772, 1776, 1777, 1780, 1783, 1788, 1797, 1798, 1805,
 1808, 1815, 1826, 1828, 1832, 1833, 1836, 1837, 1838, 1844, 1846, 1847,
 1862, 1866, 1869, 1873, 1880, 1883, 1889, 1892, 1895, 1904, 1905, 1907,
 1913, 1916, 1917, 1925, 1926, 1944, 1950, 1952, 1979, 1980, 1981, 1990,
 1995, 1999, 2001, 2011, 2012, 2014, 2018, 2024, 2030, 2031, 2032, 2045,
 2048, 2049, 2050, 2054, 2058, 2063, 2064, 2065, 2067, 2070, 2076, 2078,
 2079, 2080, 2087, 2088, 2089, 2091, 2094, 2104, 2112, 2116, 2117, 2118,
 2121, 2122, 2128, 2129, 2131, 2141, 2146, 2147, 2154, 2155, 2157, 2172,
 2176, 2181, 2182, 2183, 2185, 2190, 2193, 2195, 2207, 2212, 2218, 2228,
 2229, 2251, 2253, 2254, 2258, 2259, 2261, 2269, 2274, 2282, 2283, 2285,
 2299, 2300, 2301, 2305, 2308, 2309, 2311, 2312, 2317, 2330, 2333, 2335,
 2336, 2342, 2345, 2347, 2350, 2353, 2355, 2356, 2357, 2359, 2363, 2364,
 2369, 2378, 2380, 2384, 2394, 2400, 2403, 2404, 2406, 2411, 2413, 2414,
 2419, 2428, 2429, 2431, 2433, 2438, 2446, 2447, 2454, 2459, 2463, 2465,
 2469, 2475, 2479, 2480, 2495, 2496, 2500, 2503, 2517, 2521, 2533, 2534,
 2535, 2543, 2546, 2550, 2551, 2569, 2570, 2571, 2575, 2576, 2586, 2589,
 2591, 2595, 2598, 2600, 2602, 2614, 2615, 2617, 2622, 2623, 2629, 2631,
 2632, 2633, 2635, 2646, 2656, 2657, 2659, 2661, 2662, 2669, 2676, 2679,
 2681, 2689, 2690, 2693, 2697, 2702, 2703, 2710, 2713, 2714, 2721, 2726,
 2727, 2736, 2742, 2744, 2745, 2751, 2752, 2760, 2766, 2769, 2774, 2777,
 2778, 2786, 2793, 2800, 2802, 2805, 2813, 2814, 2823, 2833, 2838, 2841,
 2845, 2847, 2849, 2855, 2856, 2858, 2859, 2860, 2863, 2868, 2883, 2887,
 2892, 2894, 2895, 2896, 2899, 2900, 2901, 2903, 2904, 2914, 2915, 2920,
 2924, 2928, 2935, 2938, 2941, 2943, 2945, 2953, 2954, 2962, 2963, 2971,
 2973, 2974, 2976, 2978, 2981, 2982, 2986, 2987, 2991, 2994, 2996, 2999,
 3014, 3016, 3018, 3019, 3020, 3023, 3032, 3033, 3035, 3045, 3049, 3051,
 3052, 3054, 3055, 3058, 3066, 3086, 3092, 3094, 3099, 3100, 3111, 3118,
 3126, 3133, 3135, 3136, 3141, 3143, 3163, 3166, 3169, 3172, 3176, 3179,
 3184, 3193, 3194, 3202, 3207, 3220, 3225, 3226, 3235, 3239, 3241, 3243,
 3244, 3251, 3258, 3261, 3265, 3266, 3268, 3276, 3277, 3278, 3280, 3291,
 3298, 3308, 3309, 3312, 3314, 3322, 3327, 3328, 3335, 3337, 3338, 3347,
 3348, 3354, 3382, 3387, 3390, 3398, 3399, 3408, 3428, 3429, 3434, 3441,
 3442, 3449, 3450, 3454, 3461, 3462, 3468, 3473, 3485, 3487, 3495, 3504,
 3505, 3507, 3508, 3509, 3510, 3518, 3525, 3527, 3528, 3530, 3533, 3536,
 3542, 3545, 3547, 3550, 3555, 3567, 3571, 3572, 3574, 3575, 3578, 3581,
 3583, 3587, 3599, 3601, 3613, 3615, 3617, 3625, 3630, 3632, 3634, 3638,
 3641, 3642, 3647, 3650, 3651, 3655, 3661, 3667, 3674, 3686, 3688, 3689,
 3692, 3702, 3714, 3716, 3719, 3727, 3728, 3738, 3748, 3753, 3757, 3767,
 3768, 3769, 3770, 3777, 3783, 3784, 3791, 3792, 3794, 3797, 3798, 3800,
 3806, 3808, 3810, 3815, 3824, 3834, 3835, 3837, 3838, 3840, 3843, 3848,
 3849, 3854, 3857, 3860, 3861, 3866, 3878, 3885, 3890, 3895, 3896, 3898,
 3899, 3903, 3904, 3907, 3910, 3911, 3916, 3917, 3929, 3930, 3942, 3943,
 3946, 3947, 3948, 3970, 3972, 3973, 3976, 3978, 3981, 3982, 3984, 3986,
 3994, 3998, 4003, 4008, 4012, 4015, 4018, 4020, 4021, 4022, 4024, 4025,
 4026, 4030, 4035, 4038, 4041, 4044, 4056, 4057, 4063, 4066, 4067, 4071,
 4072, 4074, 4079, 4082, 4086, 4089, 4090, 4092, 4093, 4096, 4097, 4102,
 4103, 4110, 4111, 4114, 4115, 4118, 4123, 4124, 4125, 4127, 4140, 4142,
 4148, 4150, 4153, 4155, 4158, 4166, 4168, 4176, 4182, 4202, 4211, 4218,
 4230, 4235, 4241, 4242, 4269, 4273, 4280, 4282, 4284, 4295, 4298, 4303,
 4304, 4314, 4316, 4317, 4320, 4321, 4325, 4326, 4332, 4334, 4336, 4337,
 4342, 4350, 4351, 4353, 4354, 4357, 4371, 4372, 4377, 4393, 4394, 4398,
 4400, 4403, 4417, 4418, 4428, 4440, 4445, 4452, 4459, 4472, 4474, 4478,
 4481, 4487, 4494, 4501, 4502, 4504, 4505, 4517, 4519, 4536, 4540, 4549,
 4552, 4555, 4562, 4565, 4566, 4576, 4582, 4585, 4589, 4592, 4594, 4595,
 4599, 4600, 4602, 4613, 4614, 4617, 4621, 4622, 4633, 4636, 4638, 4644,
 4645, 4655, 4656, 4658, 4664, 4665, 4669, 4676, 4684, 4689, 4695, 4698,
 4699, 4709, 4713, 4716, 4724, 4727, 4728, 4729, 4734, 4735, 4737, 4739,
 4741, 4743, 4754, 4758, 4776, 4790, 4802, 4809, 4817, 4836, 4837, 4841,
 4849, 4853, 4854, 4862, 4865, 4867, 4868, 4870, 4874, 4875, 4879, 4881,
 4884, 4886, 4890, 4907, 4908, 4918, 4924, 4931, 4940, 4954, 4961, 4962,
 4969, 4978, 4980, 4983, 4984, 4993, 4997, 5002, 5008, 5010, 5013, 5021,
 5022, 5029, 5032, 5039, 5041, 5042, 5053, 5054, 5057, 5060, 5067, 5070,
 5071, 5072, 5081, 5085, 5089, 5090, 5091, 5094, 5099, 5105, 5106, 5121,
 5125, 5128, 5129, 5131, 5137, 5138, 5140, 5143, 5145, 5148, 5151, 5159,
 5163, 5164, 5171, 5179, 5183, 5185, 5186, 5192, 5195, 5204, 5209, 5210,
 5216, 5224, 5230, 5234, 5235, 5238, 5244, 5245, 5247, 5248, 5250, 5252,
 5253, 5271, 5272, 5274, 5275, 5278, 5279, 5280, 5284, 5289, 5295, 5303,
 5304, 5312, 5314, 5315, 5321, 5324, 5326, 5328, 5329, 5330, 5332, 5334,
 5335, 5336, 5340, 5343, 5347, 5349, 5353, 5357, 5358, 5365, 5367, 5370,
 5372, 5374, 5376, 5382, 5387, 5393, 5394, 5396, 5397, 5400, 5401, 5405,
 5407, 5410, 5414, 5425, 5440, 5448, 5449, 5450, 5462, 5465, 5470, 5473,
 5480, 5483, 5485, 5487, 5488, 5491, 5504, 5507, 5515, 5516, 5517, 5519,
 5523, 5524, 5525, 5530, 5535, 5538, 5540, 5557, 5563, 5564, 5580, 5583,
 5584, 5585, 5586, 5589, 5597, 5603, 5606, 5607, 5608, 5610, 5612, 5613,
 5614, 5617, 5620, 5621, 5623, 5625, 5647, 5648, 5661, 5662, 5672, 5677,
 5678, 5679, 5680, 5681, 5683, 5686, 5687, 5693, 5698, 5701, 5702, 5703,
 5704, 5707, 5712, 5713, 5718, 5724, 5727, 5732, 5739, 5748, 5756, 5759,
 5769, 5780, 5783, 5784, 5787, 5789, 5795, 5799, 5802, 5803, 5807, 5809,
 5812, 5816, 5817, 5821, 5822, 5826, 5839, 5840, 5841, 5843, 5844, 5849,
 5852, 5853, 5854, 5858, 5865, 5879, 5886, 5892, 5893, 5894, 5895, 5897,
 5899, 5902, 5908, 5914, 5916, 5919, 5920, 5926, 5927, 5937, 5942, 5943,
 5945, 5957, 5959, 5963, 5971, 5972, 5973, 5980, 5987, 5992, 5995, 6002,
 6009, 6013, 6024, 6025, 6026, 6035, 6037, 6043, 6048, 6052, 6054, 6056,
 6061, 6063, 6064, 6065, 6067, 6068, 6074, 6078, 6085, 6086, 6087, 6091,
 6092, 6094, 6095, 6096, 6100, 6103, 6104, 6113, 6116, 6117, 6132, 6134,
 6135, 6137, 6138, 6154, 6157, 6158, 6165, 6168, 6169, 6177, 6178, 6179,
 6183, 6184, 6185, 6189, 6190, 6191, 6194, 6202, 6204, 6206, 6218, 6227,
 6230, 6236, 6247, 6249, 6254, 6261, 6262, 6263, 6268, 6269, 6271, 6278,
 6282, 6292, 6297, 6321, 6326, 6332, 6344, 6345, 6349, 6351, 6352, 6353,
 6354, 6360, 6363, 6369, 6385, 6389, 6391, 6392, 6394, 6396, 6397, 6398,
 6401, 6402, 6422, 6440, 6452, 6453, 6454, 6457, 6459, 6460, 6461, 6462,
 6464, 6466, 6468, 6470, 6471, 6472, 6474, 6478, 6481, 6483, 6484, 6510,
 6511, 6512, 6519, 6531, 6539, 6540, 6544, 6546, 6547, 6548, 6552, 6557,
 6558, 6562, 6569, 6571, 6575, 6594, 6601, 6608, 6609, 6624, 6630, 6631,
 6643, 6661, 6663, 6667, 6668, 6676, 6690, 6692, 6693, 6694, 6698, 6699,
 6707, 6713, 6714, 6719, 6721, 6727, 6729, 6730, 6739, 6741, 6743, 6746,
 6749, 6751, 6756, 6769, 6771, 6776, 6786, 6787, 6791, 6792, 6800, 6814,
 6825, 6826, 6835, 6839, 6840, 6841, 6848, 6849, 6850, 6861, 6870, 6876,
 6877, 6885, 6886, 6895, 6896, 6897, 6907, 6909, 6911, 6953, 6959, 6965,
 6971, 6972, 6988, 6989, 7014, 7015, 7019, 7042, 7049, 7055, 7058, 7066,
 7070, 7073, 7078, 7080, 7083, 7091, 7115, 7116, 7123, 7124, 7126, 7132,
 7133, 7135, 7136, 7139, 7142, 7143, 7150, 7151, 7156, 7162, 7164, 7176,
 7192, 7200, 7201, 7202, 7206, 7207, 7209, 7214, 7215, 7220, 7235, 7237,
 7253, 7267, 7270, 7275, 7289, 7301, 7303, 7312, 7323, 7329, 7344, 7360,
 7369, 7379, 7388, 7397, 7398, 7410, 7431, 7438, 7445, 7447, 7455, 7457,
 7468, 7472, 7482, 7513, 7515, 7518, 7520, 7521, 7523, 7525, 7529, 7547,
 7561, 7567, 7574, 7587, 7591, 7602, 7609, 7611, 7630, 7643, 7644, 7645,
 7648, 7671, 7673, 7674, 7679, 7692, 7715, 7721, 7727, 7731, 7732, 7734,
 7735, 7738, 7749, 7759, 7767, 7770, 7776, 7790, 7796, 7808, 7815, 7828,
 7836, 7849, 7864, 7871, 7881, 7893, 7896, 7898, 7900, 7903, 7911, 7924,
 7935, 7936, 7937, 7938, 7941, 7942, 7951, 7958, 7961, 7965, 7977, 7992,
 7993, 7995, 8003, 8005, 8017, 8019, 8035, 8036, 8037, 8068, 8075, 8076,
 8078, 8087, 8097, 8114, 8115, 8134, 8138, 8149, 8164, 8168, 8174, 8207,
 8217, 8218, 8224, 8225, 8239, 8244, 8249, 8257, 8263, 8265, 8267, 8277,
 8298, 8304, 8306, 8310, 8318, 8325, 8328, 8341, 8345, 8346, 8352, 8357,
 8363, 8406, 8408, 8415, 8434, 8444, 8449, 8459, 8466, 8481, 8499, 8502,
 8503, 8518, 8521, 8534, 8549, 8553, 8557, 8582, 8588, 8623, 8644, 8663,
 8667, 8669, 8674, 8685, 8689, 8702, 8720, 8726, 8740, 8745, 8748, 8755,
 8770, 8774, 8787, 8796, 8799, 8800, 8810, 8814, 8825, 8832, 8833, 8853,
 8859, 8893, 8895, 8900, 8901, 8903, 8912, 8918, 8919, 8930, 8936, 8954,
 8960, 8963, 8976, 8981, 8986, 8988, 8990, 9006, 9007, 9010, 9025, 9038,
 9053, 9077, 9092, 9108, 9114, 9118, 9139, 9143, 9144, 9159, 9168, 9172,
 9182, 9183, 9192, 9206, 9209, 9229, 9281, 9286, 9326, 9327, 9350, 9354,
 9365, 9367, 9369, 9372, 9382, 9386, 9395, 9418, 9419, 9428, 9432, 9471,
 9496, 9568, 9582, 9591, 9612, 9622, 9624, 9625, 9638, 9640, 9668, 9670,
 9699, 9711, 9717, 9749, 9762, 9770, 9786, 9788, 9799, 9806, 9837, 9848,
 9875, 9906, 9922, 9935, 9958, 9961, 9962, 9999,10009,10013,10030,10067,
10084,10090,10102,10103,10113,10120,10155,10157,10162,10217,10228,10264,
10283,10298,10300,10302,10313,10321,10325,10342,10350,10366,10369,10375,
10384,10399,10405,10417,10420,10428,10437,10438,10443,10449,10479,10492,
10508,10522,10541,10543,10546,10548,10551,10562,10565,10589,10634,10655,
10675,10677,10709,10733,10773,10789,10801,10815,10838,10866,10867,10880,
10926,10975,10976,11018,11019,11044,11077,11092,11107,11118,11165,11179,
11241,11281,11322,11418,11471,11482,11484,11503,11519,11545,11547,11579,
11602,11653,11727,11806,11810,11815,11864,11899,11949,12001,12093,12102,
12110,12130,12251,12344,12383,12414,12445,12456,12490,12555,12580,12581,
12586,12641,12916,12944,12958,12961,13007,13021,13024,13033,13162,13204,
13230,13299,13302,13413,13427,13429,13437,13499,13529,13580,13654,13739,
13768,13773,13774,13812,13845,13964,13970,13990,14002,14029,14088,14089,
14110,14266,14351,14389,14407,14475,14485,14519,14520,14539,14549,14610,
14680,14756,14943,14963,15046,15102,15115,15163,15182,15197,15248,15258,
16707,16886,17795,17825,17844,17881,18447,18546,18868,18873,18928,19067,
19143,19964,20070,20095,20184,20220
);

# mapping for POS code and instruction code
@pos2inst = ( '*',
  'no',    'no',    'no',    'no',    'no',    
  'no',    'no',    'no',    'no',    'no',    # 10
  'no',    'no',    'no',    'no',    'no',    
  'no',    'no',    'no',    'no',    'no',    # 20
  'no',    'no',    'no',    'no',    'no',    
  'no',    'no',    'no',    'no',    'no',    # 30
  'no',    'no',    'no',    'no',    's1:sp', 
  's1:sp', 's1:sp', 's1:sp', 's1:sp', 's1:sp', # 40
  's1:sp', 'fi',    'd1:ru', 's2:sp', 'd2:ru', 
  's1:sp', 's1:sp', 's1:sp', 's1:sp', 's1:sp', # 50
  's1:sp', 's1:sp', 'fi',    'd1:ru', 's2:sp', 
  'd2:ru', 'd1:sr', 'd1:sr', 'd1:sr', 'd1:sr', # 60
  'd1:sr', 'd1:sr', 'd1:sr', 'fi',    'd1:ru', 
  'd2:sr', 'd2:sr', 'nl:ru', 'd2:ru', 'd1:sr', # 70
  'd1:sr', 'd1:sr', 'd1:sr', 'd1:sr', 'd1:sr', 
  'd1:sr', 'fi',    'd1:ru', 'd2:sr', 'd2:sr', # 80
  'nl:ru', 'd2:ru', 'd1:zr', 'd1:zr', 'd1:zr', 
  'd1:zr', 'd1:zr', 'd1:zr', 'd1:zr', 'fi',    # 90
  'd1:ru', 'd2:zr', 'd2:zr', 'nl:ru', 'd2:ru', 
  'nl:ru', 'nl:ru', 'nl:ru', 'nl:ru', 'nl:ru', # 100
  'nl:ru', 'nl:ru', 'fi',    'd1:ru', 'd1:ru', 
  'd1:ru', 'd2:ru', 'nl:ru', 'nl:ru', 'nl:ru', # 110
  'nl:ru', 'nl:ru', 'nl:ru', 'nl:ru', 'fi',    
  'd1:ru', 'd1:ru', 'd1:ru', 'd2:ru', 'nl:ru', # 120
  'nl:ru', 'nl:ru', 'nl:ru', 'nl:ru', 'nl:ru', 
  'nl:ru', 'fi',    'd1:ru', 'd1:ru', 'd1:ru', # 130
  'd2:ru', 'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', 
  'd1:ku', 'd1:ku', 'd1:ku', 'fi',    'd1:ku', # 140
  'd1:ku', 'd2:ku', 'd1:ku', 'd1:ku', 'd1:ku', 
  'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', 'fi',    # 150
  'd1:ku', 'd1:ku', 'd2:ku', 'd1:ku', 'd1:ku', 
  'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', # 160
  'fi',    'd1:ku', 'd1:ku', 'd2:ku', 'd1:ku', 
  'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', 'd1:ku', # 170
  'd1:ku', 'fi',    'd1:ku', 'd1:ku', 'd2:ku', 
  'd1:gu', 'd1:gu', 'd1:gu', 'd1:gu', 'd1:gu', # 180
  'd1:gu', 'd1:gu', 'fi',    'd1:gu', 'd1:gu', 
  'd2:gu', 'd1:su', 'd1:su', 'd1:su', 'd1:su', # 190
  'd1:su', 'd1:su', 'd1:su', 'fi',    'd1:su', 
  'd1:su', 'd2:su', 'd1:su', 'd1:su', 'd1:su', # 200
  'd1:su', 'd1:su', 'd1:su', 'd1:su', 'fi',    
  'd1:su', 'd1:su', 'd2:su', 'd1:tu', 'd1:tu', # 210
  'd1:tu', 'd1:tu', 'd1:tu', 'd1:tu', 'd1:tu', 
  'fi',    'd1:tu', 'd1:tu', 'd2:tu', 'd1:nu', # 220
  'd1:nu', 'd1:nu', 'd1:nu', 'd1:nu', 'd1:nu', 
  'd1:nu', 'fi',    'd1:nu', 'd1:nu', 'd2:nu', # 230
  'd1:bu', 'd1:bu', 'd1:bu', 'd1:bu', 'd1:bu', 
  'd1:bu', 'd1:bu', 'fi',    'd1:bu', 'd1:bu', # 240
  'd2:bu', 'd1:mu', 'd1:mu', 'd1:mu', 'd1:mu', 
  'd1:mu', 'd1:mu', 'd1:mu', 'fi',    'd1:mu', # 250
  'd1:mu', 'd2:mu', 'd1:mu', 'd1:mu', 'd1:mu', 
  'd1:mu', 'd1:mu', 'd1:mu', 'd1:mu', 'fi',    # 260
  'd1:mu', 'd1:mu', 'd2:mu', 'd1:ru', 'd1:ru', 
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', # 270
  'fi',    'd1:ru', 'd1:ru', 'd2:ru', 'd1:ru', 
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', # 280
  'd1:ru', 'fi',    'd1:ru', 'd1:ru', 'd2:ru', 
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', # 290
  'd1:ru', 'd1:ru', 'fi',    'd1:ru', 'd1:ru', 
  'd2:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', # 300
  'd1:ru', 'd1:ru', 'd1:ru', 'fi',    'd1:ru', 
  'd1:ru', 'd1:ru', 'd2:ru', 'd1:ru', 'd1:ru', # 310
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 
  'fi',    'd1:ru', 'd1:ru', 'd1:ru', 'd2:ru', # 320
  'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', 
  'd1:wu', 'fi',    'fi',    'd1:wu', 'd1:wu', # 330
  'd2:wu', 'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', 
  'd1:wu', 'd1:wu', 'fi',    'fi',    'd1:wu', # 340
  'd1:wu', 'd2:wu', 'd1:wu', 'd1:wu', 'd1:wu', 
  'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', 'fi',    # 350
  'd1:wu', 'd1:wu', 'd2:wu', 'd1:wu', 'd1:wu', 
  'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', 'd1:wu', # 360
  'fi',    'd1:wu', 'd1:wu', 'd2:wu', 'un',    
  'un',    'un',    'un',    'un',    'un',    # 370
  'un',    'un',    'un',    'un',    'un',    
  'd2:yi', 'd2:yi', 'd2:yi', 'd1:yi', 'un',    # 380
  'fi',    'd1:yi', 'd2:yi', 'd2:yi', 'nl:yi', 
  'un',    'un',    'd3:yi', 'd2:yi', 'd2:yi', # 390
  'd2:yi', 'd2:yi', 'd1:yi', 'un',    'fi',    
  'd1:yi', 'd2:yi', 'd2:yi', 'nl:yi', 'un',    # 400
  'un',    'd3:yi', 'd2:yi', 'd2:yi', 'd2:yi', 
  'd2:yi', 'd1:yi', 'un',    'fi',    'd1:yi', # 410
  'd2:yi', 'nl:yi', 'd3:yi', 'd2:yi', 'no',    
  'no',    'no',    'no',    'no',    'no',    # 420
  'no',    'r3',    'no',    'no',    'no',    
  'no',    'no',    'no',    'd1:ru', 'd1:ru', # 430
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'fi',    
  'd1:ru', 'd1:ru', 'd2:yi', 'd2:yi', 'd1:yi', # 440
  'un',    'fi',    'fi',    'd1:yi', 'd2:yi', 
  'nl:yi', 'r1',    'r1',    'r1',    'r1',    # 450
  'r1',    'r1',    'r1',    'r1',    'r1',    
  'r1',    'r1',    'r1',    'r1',    'fi',    # 460
  'r2',    'r2',    'r2',    'r2',    'r2',
  'r2',    'no',    'no',    'no',    'no',    # 470
  'no',    'no',    'no',    'd1:sr', 'd1:sr',
  'd1:sr', 'd1:sr', 'd1:sr', 'd1:sr', 'd1:sr', # 480
  'fi',    'd1:ru', 'd2:sr', 'd2:sr', 'nl:ru',
  'd2:ru', 'd2:ru', 'd3:yi', 'd2:yi', 'no',    # 490
  'no',	   'no',    'no',    'nl:ru', 'no',
  'no',	   'no',    'no',    'no',    'no',    # 500
  'no',	   'no',    'no',    'no',    'no',
  'd1:ru', 'd2:sr', 'r1',    'r1',    'd2:yi', # 510
  'd1:yi', 'fi',    'd2:yi', 'd3:yi', 'd2:yi',
  'd1:ru', 'd1:ru', 'un',    'd1:ru', 'un',    # 520
  'd1:ru', 'un',    'd1:ru', 'd1:ru', 'd1:ru', 
  'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', 'd1:ru', # 530
  'd1:ru', 'd1:ru', 'd1:ru', 'no'
);

}
