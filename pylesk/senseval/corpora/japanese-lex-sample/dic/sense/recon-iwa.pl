#!/usr/local/bin/perl

#########################################################################
# Copyright (C) 2001
#                       SHIRAI Kiyoaki
#                       School of Information Science,
#			Japan Advanced Institute of Science and Technology
#                       kshirai@jaist.ac.jp
#
# Permission to use, copy, modify and distribute this software is
# granted only for non-commercial purposes. Any copy or derived version
# should include this copyright notice. Fees for distribution or use of
# this software or derived version may only be charged with the written
# permission of the copyright holder.  This software is provided AS IS
# without express or implied warranty.
#########################################################################

##########################################################
# IMPORTANT: This file should be saved in EUC code #
##########################################################

$com = `basename $0`;	chop($com);
$usage = "$com [options]
  -D <file>	data file name (mandatory)
  -P <file>	POS tag--code mapping table (mandatory)
  -I <dir>	directory where files of IWANAMI dictionary (i01-i30)
		exists (mandatory)
";

require 'getopts.pl';
die "option error\n$usage" unless &Getopts("D:I:P:");

# open files

$DataFileName = $opt_D ? $opt_D : '';
die "-D not specified\n$usage" unless $DataFileName;
open(DATA,$DataFileName)||die "cannot open `$DataFileName'\n";

$IwaDirName = $opt_I ? $opt_I : '';
die "-I not specified\n$usage" unless $IwaDirName;
$suffix = '01';
while($suffix le '30'){
  $file_path = $IwaDirName . '/i' . $suffix;
  die "`$file_path' not exists\n" unless -e $file_path;
  $suffix++;
};

$POSMapFileName = $opt_P ? $opt_P : '';
die "-P not specified\n$usage" unless $POSMapFileName;
open(POSTBL,$POSMapFileName)||die "cannot open `$POSMapFileName'\n";
while(<POSTBL>){
  chop;
  ($code,@pos_list) = split(/\t/);
  $pos_str = join("\t",@pos_list);
  $POS_CODE{$pos_str} = $code;
};
close(POSTBL);


# main routin

while(<DATA>){
  last if /^<entry /o;
  print;
};
$CurLine = $_;
$CurLine =~ s/\n$//o;

$ws_id = '';
$mds_id = 0;
$deriv_id = -1;
$ws_num1 = 0;
$ws_num2 = 0;
$ws_num3 = 0;
$word_sense_flag = 0;

for($i=1 ; $i <= 30 ; $i++){
  $filename = ($i < 10) ? "i0$i" : "i$i" ;
  $full_path = $IwaDirName . '/' . $filename;
  open(IN,$full_path)||die("cannot open $full_path");

  while(<IN>){
    chop;
    $org_line = $_;

    if(/^<id=([0-9]+)>$/o){
      $mds_id = $1;
      print STDERR "$mds_id\r" if $mds_id % 100 == 0;

      unless($mds_id == 1){
	print "</sense>\n\n";

	$entry_tag = &read_one_entry;
	# for debug
#	die "error: $_" unless $entry_tag eq '</entry>';
	print $entry_tag, "\n\n";
      };

      $entry_tag = &read_one_entry;
      print $entry_tag, "\n\n";

      $ws_id = '';
      $deriv_id = -1;
      $ws_num1 = 0;
      $ws_num2 = 0;
      $ws_num3 = 0;
      $word_sense_flag = 0;

    }elsif(/^<MDS>/o){
      if($deriv_id == -1){
	$deriv_id++;
      }else{
	if($word_sense_flag){
	  print "</sense>\n\n";

	  $entry_tag = &read_one_entry;
	  # for debug
#	  die "error: $_" unless $entry_tag eq '</entry>';
	  print $entry_tag, "\n\n";

	  $entry_tag = &read_one_entry;
	  print $entry_tag, "\n\n";
	};

	$deriv_id++;
	$ws_num1 = 0;
	$ws_num2 = 0;
	$ws_num3 = 0;
	$ws_id = '';
	$word_sense_flag = 0;
      };

    }elsif(/^<HON>/ || /^<KHN>/){
      if($word_sense_flag){
	print "</sense>\n\n";
	$word_sense_flag = 0;
      };
     
      $deriv_id = 0 if $deriv_id == -1;
      $ws_id = sprintf("%d-%d-%d-%d-%d",
		       $mds_id,$deriv_id,$ws_num1,$ws_num2,$ws_num3);

    }elsif(/^<ws([012])=([0-9]+)>/o){
      $level = $1;
      $num = $2;
      if($word_sense_flag){
	print "</sense>\n\n";
      };

      if($level == 0){
	# for debug
#	print STDERR "Warning: $filename $mds_id $level $num\n"
#	  unless $ws_num1 + 1 == $num;
	$ws_num1 = $num;
	$ws_num2 = 0;
	$ws_num3 = 0;
      }elsif($level == 1){
	# for debug
#	print STDERR "Warning: $filename $mds_id $level $num\n"
#	  unless $ws_num2 + 1 == $num;
	# �㳰����: ����פ�(��ݤ�2)�Ȥ��������٥뤬2�Ĥ���
	# 	    ��˽ФƤ�������(��ݤ�3)���Ѥ���
	if($mds_id eq '48433' && $ws_num2 + 1 != $num){
	  $ws_num2 = 3;
	}else{
	  $ws_num2 = $num;
	};
	$ws_num3 = 0;
      }elsif($level == 2){
	# for debug
#	print STDERR "Warning: $filename $mds_id $level $num\n"
#	  unless $ws_num3 + 1 == $num;
	$ws_num3 = $num;
      };
      $ws_id = sprintf("%d-%d-%d-%d-%d",
		    $mds_id,$deriv_id,$ws_num1,$ws_num2,$ws_num3);

      printf "<sense id=\"%s\">\n", $ws_id;
      $word_sense_flag = 1;

    }elsif($ws_id ne ''){
      printf "<sense id=\"%s\">\n", $ws_id unless $word_sense_flag;
      $word_sense_flag = 1;

      if( defined $ExtTag{$_} ){
	$tmp = $_;
	$tmp =~ s/^</&lt;/o;
	$tmp =~ s/>$/&gt;/o;
	print $tmp, "\n";

      # <RB> ���㳰����
      #   <RB>ñ��</RB>
      #   <RB>�ɥ���</RB>	�ɥ���	�ɥ���	̾��	��ͭ̾��	�ϰ�	��
      #   <RB>�ե��</RB>	�ե��	�ե��	̾��	��ͭ̾��	�ϰ�	��
      }elsif(/^<RB>([^<>]+)<\/RB>[^<>]*$/o){
	$word = $1;
	($tmp,$yomi,$base,@pos_list) = split(/\t/);
	print "&lt;RB&gt;\n";
	if($yomi){	# �嵭2�㤷���ʤ��Ϥ�
	  printf "<mor pos=\"8\" rd=\"%s\">%s</mor>\n", $yomi, $word;
	}else{
	  printf "<mor>%s</mor>\n", $word;
	};
	print "&lt;/RB&gt;\n";

      # <RB> ���㳰����
      #   <RB>�ݥ�ȥ���</RB>��<RB>���ڥ���</RB>
      #   <RB>�ե��</RB>��<RB>�����ꥹ</RB>
      }elsif(/^<RB>([^<>]+)<\/RB>��<RB>([^<>]+)<\/RB>$/o){
	$a = $1;
	$b = $2;
	print "&lt;RB&gt;\n";
	printf "<mor pos=\"8\" rd=\"%s\">%s</mor>\n", $a, $a;
	print "&lt;/RB&gt;\n";
	print "<mor pos=\"468\" rd=\"��\">��</mor>\n";
	print "&lt;RB&gt;\n";
	printf "<mor pos=\"8\" rd=\"%s\">%s</mor>\n", $b, $b;
	print "&lt;/RB&gt;\n";

      }elsif(/^(<[^0-9].*>)$/o){
	$tag = $1;
	if( ($str = $TagTable{$tag}) ){
	  print $str, "\n" unless $str eq 'ignore';
	}else{
	  # for debug
#	  die "ERROR(unknown tag): $_\n";
	};
      }else{
	($word,$yomi,$base,@pos_list) = split(/\t/);

	# �����ν���
	$word =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$yomi =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$base =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$word =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;
	$yomi =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;
	$base =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;

	$yomi = '�⥦������'
	  if $mds_id == 51051 && $yomi eq '�⥦������';

	# ��Ӥν���
	# �ʲ��Υ����פΥ�Ӥϡ�ruby�����Ȥ���mor�����������ࡣ
	# �ͤ� �֥�Ӥ˳�������ɽ��:��ӡ� �Ȥ��롣
	# (���겾̾�������ɽ���ȥ�Ӥ����פ��ʤ�����)
	#
	# ex.
	# �������<RB>���Ҥ���</RB>��	���ҥ���	�����	1
	# �� <mor pos="1" rd="���ҥ���"><ruby rd="���Ҥ���">�����</ruby></mor>
	#
	# �С�<RB>��</RB>�ˤ�	����	����	 �Ф�	371
	# �� <mor pos="371" rd="����" bfm="�Ф�"><ruby rd="��">��</ruby>��</mor>
	if($RubiReigai{$word}){
	  $word = $RubiReigai{$word};
	}elsif($word =~ /^(.+)��<RB>([^<>]+)<\/RB>��([^<>]*)$/o){
	  $word = sprintf "<ruby rd=\"%s\">%s</ruby>%s", $2, $1, $3;
	}elsif($word =~ /^(.+)��<RB>([^<>]+)<\/RB>��<RB>([^<>]+)<\/RB>��([^<>]*)$/o){
	  # ex. ��̼��<RB>�������褦</RB>��<RB>�ޤʤह��</RB>�� 
	  $word = sprintf "<ruby rd=\"%s,%s\">%s</ruby>%s", $2, $3, $1, $4;
	}elsif($word =~ /^(.+)��<RB>([^<>]+)<\/RB>��<RB>([^<>]+)<\/RB>��<RB>([^<>]+)<\/RB>��([^<>]*)$/o){
	  # ex. �۰��<RB>�դ�</RB>��<RB>�ۤ�</RB>��<RB>�ۤ���</RB>��
	  $word = sprintf "<ruby rd=\"%s,%s,%s\">%s</ruby>%s", $2, $3, $4, $1, $5;
	}elsif($word =~ /^(.+)<RB>([^<>]+)<\/RB>([^<>]*)$/o){
	  $word = sprintf "<ruby rd=\"%s\">%s</ruby>%s", $2, $1, $3;
	};

	# for debug
	die "< or > included (hyouki): $word\n" if &check_tag($word);
	die "< or > included (yomi): $yomi\n" if &check_tag($yomi);
	die "< or > included (base): $base\n"
	  if ($pos_list[0] eq 'ư��' || $pos_list[0] eq '���ƻ�' ||
	      $pos_list[0] eq '��ư��') && &check_tag($base);

	$pos = join("\t",@pos_list);
	$pos_code = $POS_CODE{$pos};
	print "<mor";
	printf " pos=\"%d\"", $pos_code if $#pos_list >= 0;
	printf " rd=\"%s\"", $yomi if $yomi;
	printf " bfm=\"%s\"", $base
	  if $pos_list[0] eq 'ư��' || $pos_list[0] eq '���ƻ�' ||
	     $pos_list[0] eq '��ư��';
	printf ">%s</mor>\n", $word;
      };
    };

    $prev_line = $org_line;
  };
};

print "</sense>\n\n";
print "$CurLine\n";
while(<DATA>){
  print;
};

sub read_one_entry {
  local($entry_id,$entry_tag);

  if($CurLine =~ /^<entry id=\"([^\"]+)\".+>$/o){
    $entry_tag = $CurLine;

    $CurLine = <DATA>;
    $CurLine =~ s/\n$//o;

    return($entry_tag);

  }elsif($CurLine eq '</entry>'){
    $entry_tag = $CurLine;

    $CurLine = <DATA>;
    $CurLine =~ s/\n$//o;

    return($entry_tag);

  }else{
    return(-1);
  };
};

sub check_tag {
  local($str) = @_;
  local($str2);

  while($str =~ s/<([^<>]+)>//o){
    $str2 = $1;
    # <ruby>������OK
    return(1) unless $str2 =~ /^ruby /o || $str2 eq '/ruby';
  };
  return(0);
};

BEGIN {

%ExtTag = (
  '<EX>',	1,
  '</EX>',	-1,
  '<EX0>',	1,
  '</EX0>',	-1,
  '<IT>',	1,
  '</IT>',	-1,
  '<ALP>',	1,
  '</ALP>',	-1,
  '<KNZ>',	1,
  '</KNZ>',	-1,
  '<SUP>',	1,
  '</SUP>',	-1,
  '<SUB>',	1,
  '</SUB>',	-1,
  '<REF>',	1,
  '</REF>',	-1,
  '<RB>',	1,
  '</RB>',	-1,
  '<POS>',	1,
  '</POS>',	-1,
  '<GHK>',	1,
  '</GHK>',	-1,
  '<GHS>',	1,
  '</GHS>',	-1
);

%TagTable = (
  '<+>',	'ignore',
  '<rs0=1>',    '<mor rsl="0" rsn="1">�ʰ��</mor>',
  '<rs0=2>',    '<mor rsl="0" rsn="2">�����</mor>',
  '<rs0=3>',    '<mor rsl="0" rsn="3">�ʻ���</mor>',
  '<rs0=4>',    '<mor rsl="0" rsn="4">�ʻ͡�</mor>',
  '<rs0=6>',    '<mor rsl="0" rsn="6">��ϻ��</mor>',
  '<rs1=1>',    '<mor rsl="1" rsn="1">��1��</mor>',
  '<rs1=2>',    '<mor rsl="1" rsn="2">��2��</mor>',
  '<rs1=3>',    '<mor rsl="1" rsn="3">��3��</mor>',
  '<rs1=4>',    '<mor rsl="1" rsn="4">��4��</mor>',
  '<rs1=5>',    '<mor rsl="1" rsn="5">��5��</mor>',
  '<rs1=6>',    '<mor rsl="1" rsn="6">��6��</mor>',
  '<rs1=7>',    '<mor rsl="1" rsn="7">��7��</mor>',
  '<rs1=8>',    '<mor rsl="1" rsn="8">��8��</mor>',
  '<rs1=9>',    '<mor rsl="1" rsn="9">��9��</mor>',
  '<rs1=10>',   '<mor rsl="1" rsn="10">��10��</mor>',
  '<rs2=1>',    '<mor rsl="2" rsn="1">�ʥ���</mor>',
  '<rs2=2>',    '<mor rsl="2" rsn="2">�ʥ���</mor>',
  '<rs2=3>',    '<mor rsl="2" rsn="3">�ʥ���</mor>',
  '<rs2=4>',    '<mor rsl="2" rsn="4">�ʥ���</mor>',
  '<rs2=5>',    '<mor rsl="2" rsn="5">�ʥ���</mor>',
  '<rs2=6>',    '<mor rsl="2" rsn="6">�ʥ���</mor>',
  '<rs2=7>',    '<mor rsl="2" rsn="7">�ʥ���</mor>',
  '<rs2=8>',    '<mor rsl="2" rsn="8">�ʥ���</mor>',
  '<rs2=9>',    '<mor rsl="2" rsn="9">�ʥ���</mor>'
);

%RubiReigai = (
  '����ҡ�<RB>���ޤ���</RB><RB>����</RB>��',
	'<ruby rd="���ޤ��褦��">�����</ruby>',
  '����<RB>��</RB>�ˤˤ�����<RB>��</RB>��',
	'<ruby rd="��">��</ruby>�ˤ�<ruby rd="��">��</ruby>',
  '����<RB>����</RB>�ˤ��á�<RB>����</RB>��',
	'<ruby rd="����">��</ruby>��<ruby rd="����">��</ruby>',
  '����<RB>�����餯</RB>��<RB>���餯</RB>',
	'<ruby rd="�����餯,���餯">����</ruby>',
  '��<133=�ȥ��>��<RB>�����Ȥ�</RB>��',
	'<ruby rd="�����Ȥ�">��<133=�ȥ��></ruby>',
# <EX> ��̵�뤹��
  '������<EX>��</EX>��<RB>�ߤ��Ť�����</RB>��',
	'<ruby rd="�ߤ��Ť�����">�������</ruby>',
  '���ڵ���<RB>���󤻤Ĥ�</RB>��<RB>���󤻤Ĥ�</RB>',
	'<ruby rd="���󤻤Ĥ�,���󤻤Ĥ�">���ڵ�</ruby>',
  '������<RB>���椦����</RB>��<RB>����</RB>��<RB>����</RB>��<RB>����</RB>��',
	'<ruby rd="���夦����,����,����,����">����</ruby>',
  '�����<RB>���褸�褦</RB>����<RB>��褦��</RB>��',
	'<ruby rd="���褸�褦,��褦��">����</ruby>',
  '�ʶġ�<RB>�������褦</RB>��<RB>��������</RB>',
	'<ruby rd="�������褦,��������">�ʶ�</ruby>',
  '������<RB>����</RB><RB>����</RB>��',
	'<ruby rd="���褦��">����</ruby>',
  '�ݡ�<RB>����</RB>�˼��<RB>����</RB>��',
	'<ruby rd="����">��</ruby><ruby rd="����">��</ruby>',
  '����<RB>����</RB>������<RB>��</RB>��',
	'<ruby rd="����">��</ruby><ruby rd="��">��</ruby>',
  '���<RB>����</RB>������<RB>��</RB>��',
	'<ruby rd="����">��</ruby><ruby rd="��">��</ruby>',
  '����<RB>��</RB>�����<RB>��</RB>��',
	'<ruby rd="��">��</ruby><ruby rd="��">��</ruby>',
  'ƻ��<RB>��</RB>�˸ԡ�<RB>�ޤ�</RB>��',
	'<ruby rd="��">ƻ</ruby><ruby rd="�ޤ�">��</ruby>',
  '��ɱ��<RB>����</RB><RB>����</RB>��',
	'<ruby rd="���褦��">��ɱ</ruby>',
  '����>��<RB>����</RB>��',
	'<ruby rd="����">����</ruby>',
  '����<RB>�Ȥ�</RB>�ˤδ֡�<RB>��</RB>��',
	'<ruby rd="�Ȥ�">��</ruby>��<ruby rd="��">��</ruby>',
  '�ˡ�<RB>��</RB>�ˤ����<RB>�ʤ�</RB>��',
	'<ruby rd="��">��</ruby>��<ruby rd="�ʤ�">��</ruby>',
  '���<RB>��</RB>�ˤ���<RB>����</RB>�ˤ�',
	'<ruby rd="��">��</ruby>��<ruby rd="����">��</ruby>��',
  '���<RB>��</RB>�ˤ���<RB>����</RB>�ˤϤ�',
	'<ruby rd="��">��</ruby>��<ruby rd="����">��</ruby>�Ϥ�',
  '���<RB>����</RB>�ˤ�̿��<RB>�ᤤ</RB>��',
	'<ruby rd="����">��</ruby>��<ruby rd="�ᤤ">̿</ruby>',
  'ˡ���<RB>�ۤ�����</RB>��<RB>�ۤĤ�</RB>��<RB>�ۤĤ���</RB>',
	'<ruby rd="�ۤ�����,�ۤĤ�,�ۤĤ���">ˡ��</ruby>',
  '�ܡ�<RB>��</RB>��á����<RB>����</RB>��',
	'<ruby rd="��">��</ruby><ruby rd="����">á</ruby>��',
  '�ܡ�<RB>��</RB>��á����<RB>�Ϥ�</RB>��',
	'<ruby rd="��">��</ruby><ruby rd="�Ϥ�">á</ruby>��',
  '�ܡ�<RB>��</RB>�˼��<RB>��</RB>�ˤ�',
	'<ruby rd="��">��</ruby><ruby rd="��">��</ruby>��',
  '����<RB>��</RB>�ˤ�����<RB>��</RB>��',
	'<ruby rd="��">��</ruby>��<ruby rd="��">��</ruby>',
  '�ܡ�<RB>��</RB>�˰š�<RB>����</RB>��',
	'<ruby rd="��">��</ruby><ruby rd="����">��</ruby>',
  'ǡ����<RB>�ˤ�</RB><RB>�����</RB>�˴Ѳ�',
	'<ruby rd="�ˤ褤���">ǡ����</ruby>�Ѳ�'
);

};
