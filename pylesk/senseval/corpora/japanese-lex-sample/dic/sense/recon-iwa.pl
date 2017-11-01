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
	# 例外処理: 「枚」は(白丸の2)という語義ラベルが2つある
	# 	    後に出てくる方を(白丸の3)に変える
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

      # <RB> の例外処理
      #   <RB>単語</RB>
      #   <RB>ドイツ</RB>	ドイツ	ドイツ	名詞	固有名詞	地域	国
      #   <RB>フランス</RB>	フランス	フランス	名詞	固有名詞	地域	国
      }elsif(/^<RB>([^<>]+)<\/RB>[^<>]*$/o){
	$word = $1;
	($tmp,$yomi,$base,@pos_list) = split(/\t/);
	print "&lt;RB&gt;\n";
	if($yomi){	# 上記2例しかないはず
	  printf "<mor pos=\"8\" rd=\"%s\">%s</mor>\n", $yomi, $word;
	}else{
	  printf "<mor>%s</mor>\n", $word;
	};
	print "&lt;/RB&gt;\n";

      # <RB> の例外処理
      #   <RB>ポルトガル</RB>・<RB>スペイン</RB>
      #   <RB>フランス</RB>・<RB>イギリス</RB>
      }elsif(/^<RB>([^<>]+)<\/RB>・<RB>([^<>]+)<\/RB>$/o){
	$a = $1;
	$b = $2;
	print "&lt;RB&gt;\n";
	printf "<mor pos=\"8\" rd=\"%s\">%s</mor>\n", $a, $a;
	print "&lt;/RB&gt;\n";
	print "<mor pos=\"468\" rd=\"・\">・</mor>\n";
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

	# 外字の処理
	$word =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$yomi =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$base =~ s/<([0-9]+)>/&lt;$1&gt;/go;
	$word =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;
	$yomi =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;
	$base =~ s/<([0-9]+=[^<>]+)>/&lt;$1&gt;/go;

	$yomi = 'モウコアザ'
	  if $mds_id == 51051 && $yomi eq 'モウコアザ';

	# ルビの処理
	# 以下のタイプのルビは、rubyタグとしてmorタグに埋め込む。
	# 値は 「ルビに該当する表記:ルビ」 とする。
	# (送り仮名があると表記とルビが一致しないため)
	#
	# ex.
	# 亜砒酸（<RB>あひさん</RB>）	アヒサン	亜砒酸	1
	# → <mor pos="1" rd="アヒサン"><ruby rd="あひさん">亜砒酸</ruby></mor>
	#
	# 出（<RB>い</RB>）で	イデ	いづ	 出づ	371
	# → <mor pos="371" rd="イデ" bfm="出づ"><ruby rd="い">出</ruby>で</mor>
	if($RubiReigai{$word}){
	  $word = $RubiReigai{$word};
	}elsif($word =~ /^(.+)（<RB>([^<>]+)<\/RB>）([^<>]*)$/o){
	  $word = sprintf "<ruby rd=\"%s\">%s</ruby>%s", $2, $1, $3;
	}elsif($word =~ /^(.+)（<RB>([^<>]+)<\/RB>・<RB>([^<>]+)<\/RB>）([^<>]*)$/o){
	  # ex. 愛娘（<RB>あいじよう</RB>・<RB>まなむすめ</RB>） 
	  $word = sprintf "<ruby rd=\"%s,%s\">%s</ruby>%s", $2, $3, $1, $4;
	}elsif($word =~ /^(.+)（<RB>([^<>]+)<\/RB>・<RB>([^<>]+)<\/RB>・<RB>([^<>]+)<\/RB>）([^<>]*)$/o){
	  # ex. 布衣（<RB>ふい</RB>・<RB>ほい</RB>・<RB>ほうい</RB>）
	  $word = sprintf "<ruby rd=\"%s,%s,%s\">%s</ruby>%s", $2, $3, $4, $1, $5;
	}elsif($word =~ /^(.+)<RB>([^<>]+)<\/RB>([^<>]*)$/o){
	  $word = sprintf "<ruby rd=\"%s\">%s</ruby>%s", $2, $1, $3;
	};

	# for debug
	die "< or > included (hyouki): $word\n" if &check_tag($word);
	die "< or > included (yomi): $yomi\n" if &check_tag($yomi);
	die "< or > included (base): $base\n"
	  if ($pos_list[0] eq '動詞' || $pos_list[0] eq '形容詞' ||
	      $pos_list[0] eq '助動詞') && &check_tag($base);

	$pos = join("\t",@pos_list);
	$pos_code = $POS_CODE{$pos};
	print "<mor";
	printf " pos=\"%d\"", $pos_code if $#pos_list >= 0;
	printf " rd=\"%s\"", $yomi if $yomi;
	printf " bfm=\"%s\"", $base
	  if $pos_list[0] eq '動詞' || $pos_list[0] eq '形容詞' ||
	     $pos_list[0] eq '助動詞';
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
    # <ruby>タグはOK
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
  '<rs0=1>',    '<mor rsl="0" rsn="1">（一）</mor>',
  '<rs0=2>',    '<mor rsl="0" rsn="2">（二）</mor>',
  '<rs0=3>',    '<mor rsl="0" rsn="3">（三）</mor>',
  '<rs0=4>',    '<mor rsl="0" rsn="4">（四）</mor>',
  '<rs0=6>',    '<mor rsl="0" rsn="6">（六）</mor>',
  '<rs1=1>',    '<mor rsl="1" rsn="1">（1）</mor>',
  '<rs1=2>',    '<mor rsl="1" rsn="2">（2）</mor>',
  '<rs1=3>',    '<mor rsl="1" rsn="3">（3）</mor>',
  '<rs1=4>',    '<mor rsl="1" rsn="4">（4）</mor>',
  '<rs1=5>',    '<mor rsl="1" rsn="5">（5）</mor>',
  '<rs1=6>',    '<mor rsl="1" rsn="6">（6）</mor>',
  '<rs1=7>',    '<mor rsl="1" rsn="7">（7）</mor>',
  '<rs1=8>',    '<mor rsl="1" rsn="8">（8）</mor>',
  '<rs1=9>',    '<mor rsl="1" rsn="9">（9）</mor>',
  '<rs1=10>',   '<mor rsl="1" rsn="10">（10）</mor>',
  '<rs2=1>',    '<mor rsl="2" rsn="1">（ア）</mor>',
  '<rs2=2>',    '<mor rsl="2" rsn="2">（イ）</mor>',
  '<rs2=3>',    '<mor rsl="2" rsn="3">（ウ）</mor>',
  '<rs2=4>',    '<mor rsl="2" rsn="4">（エ）</mor>',
  '<rs2=5>',    '<mor rsl="2" rsn="5">（オ）</mor>',
  '<rs2=6>',    '<mor rsl="2" rsn="6">（カ）</mor>',
  '<rs2=7>',    '<mor rsl="2" rsn="7">（キ）</mor>',
  '<rs2=8>',    '<mor rsl="2" rsn="8">（ク）</mor>',
  '<rs2=9>',    '<mor rsl="2" rsn="9">（ケ）</mor>'
);

%RubiReigai = (
  '雨障子（<RB>あましよ</RB><RB>うじ</RB>）',
	'<ruby rd="あましようじ">雨障子</ruby>',
  '往（<RB>い</RB>）にし方（<RB>へ</RB>）',
	'<ruby rd="い">往</ruby>にし<ruby rd="へ">方</ruby>',
  '現（<RB>うつ</RB>）し臣（<RB>おみ</RB>）',
	'<ruby rd="うつ">現</ruby>し<ruby rd="おみ">臣</ruby>',
  '快楽<RB>かいらく</RB>・<RB>けらく</RB>',
	'<ruby rd="かいらく,けらく">快楽</ruby>',
  '角<133=トリデ>（<RB>かくとう</RB>）',
	'<ruby rd="かくとう">角<133=トリデ></ruby>',
# <EX> は無視する
  '三日月<EX>形</EX>（<RB>みかづきがた</RB>）',
	'<ruby rd="みかづきがた">三日月形</ruby>',
  '親切気（<RB>しんせつぎ</RB>・<RB>しんせつげ</RB>',
	'<ruby rd="しんせつぎ,しんせつげ">親切気</ruby>',
  '救世（<RB>きゆうせい</RB>・<RB>くせ</RB>・<RB>くぜ</RB>・<RB>ぐぜ</RB>）',
	'<ruby rd="きゅうせい,くせ,くぜ,ぐぜ">救世</ruby>',
  '漁場（<RB>ぎよじよう</RB>・・<RB>りようば</RB>）',
	'<ruby rd="ぎよじよう,りようば">漁場</ruby>',
  '景仰（<RB>けいぎよう</RB>・<RB>けいこう</RB>',
	'<ruby rd="けいぎよう,けいこう">景仰</ruby>',
  '娼妓（<RB>しよ</RB><RB>うぎ</RB>）',
	'<ruby rd="しようぎ">娼妓</ruby>',
  '旨（<RB>うま</RB>）酒（<RB>さけ</RB>）',
	'<ruby rd="うま">旨</ruby><ruby rd="さけ">酒</ruby>',
  '下（<RB>しも</RB>）部（<RB>べ</RB>）',
	'<ruby rd="しも">下</ruby><ruby rd="べ">部</ruby>',
  '後（<RB>しり</RB>）方（<RB>へ</RB>）',
	'<ruby rd="しり">後</ruby><ruby rd="へ">方</ruby>',
  '狭（<RB>せ</RB>）門（<RB>と</RB>）',
	'<ruby rd="せ">狭</ruby><ruby rd="と">門</ruby>',
  '道（<RB>ち</RB>）股（<RB>また</RB>）',
	'<ruby rd="ち">道</ruby><ruby rd="また">股</ruby>',
  '寵姫（<RB>ちよ</RB><RB>うき</RB>）',
	'<ruby rd="ちようき">寵姫</ruby>',
  '喧嘩>（<RB>げんか</RB>）',
	'<ruby rd="げんか">喧嘩</ruby>',
  '床（<RB>とこ</RB>）の間（<RB>ま</RB>）',
	'<ruby rd="とこ">床</ruby>の<ruby rd="ま">間</ruby>',
  '破（<RB>わ</RB>）れ鍋（<RB>なべ</RB>）',
	'<ruby rd="わ">破</ruby>れ<ruby rd="なべ">鍋</ruby>',
  '宣（<RB>の</RB>）り給（<RB>たま</RB>）ふ',
	'<ruby rd="の">宣</ruby>り<ruby rd="たま">給</ruby>ふ',
  '宣（<RB>の</RB>）り給（<RB>たま</RB>）はく',
	'<ruby rd="の">宣</ruby>り<ruby rd="たま">給</ruby>はく',
  '上（<RB>かみ</RB>）の命（<RB>めい</RB>）',
	'<ruby rd="かみ">上</ruby>の<ruby rd="めい">命</ruby>',
  '法主（<RB>ほうしゆ</RB>・<RB>ほつす</RB>・<RB>ほつしゆ</RB>',
	'<ruby rd="ほうしゆ,ほつす,ほつしゆ">法主</ruby>',
  '目（<RB>ま</RB>）叩く（<RB>たた</RB>）',
	'<ruby rd="ま">目</ruby><ruby rd="たた">叩</ruby>く',
  '目（<RB>ま</RB>）叩き（<RB>はた</RB>）',
	'<ruby rd="ま">目</ruby><ruby rd="はた">叩</ruby>き',
  '目（<RB>ま</RB>）守（<RB>も</RB>）る',
	'<ruby rd="ま">目</ruby><ruby rd="も">守</ruby>る',
  '生（<RB>む</RB>）す女（<RB>め</RB>）',
	'<ruby rd="む">生</ruby>す<ruby rd="め">女</ruby>',
  '目（<RB>ま</RB>）暗（<RB>ぐれ</RB>）',
	'<ruby rd="ま">目</ruby><ruby rd="ぐれ">暗</ruby>',
  '如意輪<RB>によ</RB><RB>いりん</RB>）観音',
	'<ruby rd="によいりん">如意輪</ruby>観音'
);

};
