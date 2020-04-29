#!/usr/bin/perl
#
# utau2sinsy - ust(of UTAU)-MusicXML(for Sinsy) converter
#
#            - UTAUのustファイルを読み込み Sinsy 用の MusicXML を出力する。
#
#
# ＜使用方法その1 ～WSLやコマンドプロンプトで使用＞
#
#   XML::Smart と Unicode::Japanese モジュールをインストールした上で、
#   以下の様に実行して下さい。
#     % perl ./utau2sinsy.pl ./sample.ust
#
#     ※モジュールインストールの例(cygwin)
#         > perl -MCPAN -e shell
#         cpan> install XML::Smart
#         cpan> install Unicode::Japanese
#         cpan> exit
#     ※モジュールインストールの例(activetcl)
#         > ppm install XML::Smart
#         > ppm install XML::Smart
#
#   sample.ust と同じフォルダに sample.xml という結果ファイルが作られます。
#   これを Sinsy (http://www.sinsy.jp/) に与えて下さい。
#
#   モジュールが無い場合、必要と思われるモジュールをlib/以下にコピーしてありますので
#   以下のように実行してみて下さい(環境によってはうまくいかないかもしれません)。
#
#     % perl -I./lib ./utau2sinsy.pl ./sample.ust
#
# ＜注意事項＞
#
#   結果ファイルと同名のファイルが既に存在している場合、無断で上書きします。
#   ご注意下さい。
#
#   本ファイルは shift-jis で保存して下さい。
#
#   汎用的な MusicXML の出力ではなく、あくまで現時点(2010/05/02現在)の
#   Sinsy が処理できる程度の XML を出力します。
#   作者は MusicXML についての詳しい知識は持ち合わせていません。
#   譜面表示については 今のところ MuseScore(http://www.musescore.org/)で
#   表示確認しています。
#
#   未検証の部分もあるかもしれません。
#   UTAUのstpパラメータやピッチなどは反映されません。
#   各音符の高さ、長さ、音名のみからXMLを生成しています。
#
# ＜ライセンス＞
#
#   cygwin-perlのライブラリを再配布していますので、
#   本スクリプトはcygwinのライセンスと同じGPLライセンスとしてお使い下さい。
#
# ＜変更記録＞
#
#   2011/05/06 ver.0.16
#     - テンプレートXMLのファイル名間違いを修正した。
#   2010/09/14 ver.0.15
#     - ３連符に対応した（ただし複雑な構造の連符では失敗するかも）。
#     - MuseScoreがテンポ情報を認識、変更できるようにした。
#     - 休符が連続した場合は１つにまとめるようにした。
#     - 最後の小節にきりの良い休符が入っていない場合は挿入するようにした。
#   2010/05/04 ver.0.14
#     - 一オクターブを超えるタイに対応
#     - 休符の音の高さをC4にする
#     - 音符長の一の位を四捨五入する（簡易クオンタイズ）
#   2010/01/13 ver.0.13
#     - 二重付点音符に対応
#   2010/01/13 ver.0.12
#     - XML::Smartモジュールでxml処理するようにした。
#     - XMLのテンプレートを読むようにした。
#     - 小節をまたぐ音符に対応(分解してタイでつなぐ)。
#     - 付点音符に対応
#   2010/01/08 ver.0.11
#     - MuseScoreである程度楽譜表示されるようにした。まだ不具合が多々あります。
#     - UTF-8 で出力するようにした。
#     - タグの長さに応じて改行コードを入れたり入れなかったりするようにした。
#   2010/01/06 ver.0.1 公開


# ↓以下の行は、cygwin版perlで実行し、かつ必要なモジュールをインストールしていない
#   場合に限り有効にすること。
#use lib './lib';

#use strict;
use Unicode::Japanese;
use XML::Smart;
use File::Basename;


#------------------------------------------------------------------
# 変数設定など
# 

my $appname = 'utau2sinsy.pl';
my $version = '0.16';
my $encoding = 'UTF-8';
my $appDir = dirname($0);
my $templeteFile = "$appDir/template.xml";

# 大域変数
our $tempo     = 100;  # テンポ
our $divisions = 480;  # 四分音符の分解能
our $beats     = 4;    # 拍子
our $beatType  = 4;    # ○分の..
our $useTie    = 1;    # 1=音長が小節区切りをまたぐ際等にタイを使う

# ↓付点音符には音符名末尾にDをつけている。
our @lengthList = qw( 1920    1680     1440   960     840       720      480     420
                      360     320      240    210     180       160      120     105      90      80     60   
                      52.5    45       30     26.25   22.5      15       13.125  11.25  7.5);
our @typeList   = qw( whole   halfDD   halfD  half    quarterDD quarterD quarter eighthDD
                      eighthD quarterT eighth 16thDD  16thD     eighthT  16th    32ndDD   32ndD   16thT  32nd 
                      64thDD  64thD    64th   128thDD 128thD    128th    256thDD 256thD 256th);

#------------------------------------------------------------------
# 引数チェック
#
if (@ARGV < 2){
  print "error: syntax error\n\n";
  print "usage: $0 ustFile xmlfile \n";
  
  exit 1;
}

## Windows形式の表現ならcygwin(unix)形式にする
#if ($ARGV[0] =~ /\\/){
#  $ARGV[0] =~ s/^([a-zA-Z]):/\/cygdrive\/$1/;
#  $ARGV[0] =~ s/\\/\//g;
#}

my $inFile = $ARGV[0];

# 結果出力ファイル名を作成
my $outFile = $ARGV[1];
# $outFile =~ s/ust$/xml/;

# 実行日を取得
my @ltime = localtime(time);
my $encodeDate = sprintf ("%04d-%02d-%02d", $ltime[5]+1900,$ltime[4]+1,$ltime[3]);

#------------------------------------------------------------------
#
# 本文
#
my $XML = XML::Smart->new($templeteFile);
my $enc = $XML->{'score-partwise'}{'identification'}{'encoding'};
$enc->{'software'}->content("$appname version $version");
$enc->{'encoding-date'}->content($encodeDate);

# ustファイルを読み、テンポ、音符データを取得
my @note = readUst($inFile);

# １小節の長さを計算
my $measureLength = $divisions * $beats / ($beatType / 4);

# テンポや拍子を設定する
my $measure = $XML->{'score-partwise'}{'part'}{'measure'};
$measure->{'direction'}{'sound'} = { 'tempo' => $tempo };
$measure->{'attributes'}{'divisions'}->content($divisions);
$measure->{'attributes'}{'time'}{'beats'}->content($beats);
$measure->{'attributes'}{'time'}{'beat-type'}->content($beatType);

# 連続休符を結合する
uniqR (\@note);

# タイを設定する
setTie (\@note, $measureLength) if $useTie;

# 3連符をまとめる
setTuplet (\@note);

# 音符データを設定する
my $len = 0;
my $mseq = 0;     # measure の*配列*番号
foreach my $n (@note) {
  $len += $n->{duration};
  insertNote ($measure->[$mseq]{'note'}, $n);
  if ($len >= $measureLength) {
    $mseq++;
    my $mtmp = $mseq + 1;
    push (@$measure, { 'number' => "$mtmp" });
    $len -= $measureLength;
  }
}

# 出力
$XML->save($outFile);

#print "-------- 変換終了 --------\n";
#print "入力ファイル= $inFile\n出力ファイル= $outFile\n";
#print "-- ENTER を押して下さい --\n";
print "-------- Convert Success --------\n";
print "$inFile -----> $outFile\n";

#-------------------------------------------------------
# 一音符のタグを追記
#
sub insertNote {
  my ($noteXML, $note) = @_;

  push (@$noteXML, {});
  my $nseq = @$noteXML - 1;

  $noteXML->[$nseq]{'pitch'}{'step'}  ->content($note->{'pitchStep'});
  $noteXML->[$nseq]{'pitch'}{'octave'}->content($note->{'pitchOctave'});
  $noteXML->[$nseq]{'pitch'}{'alter'} ->content($note->{'pitchAlter'});
  $noteXML->[$nseq]{'duration'}       ->content($note->{'duration'});
  $noteXML->[$nseq]{'type'}           ->content($note->{'type'});
  $noteXML->[$nseq]{'voice'}          ->content(1);
  $noteXML->[$nseq]{'staff'}          ->content(1);
  $noteXML->[$nseq]{'dot'}->set_node()    if ($note->{'dot'} > 0);
  $noteXML->[$nseq]{'dot'}[1]->set_node() if ($note->{'dot'} >= 2);

  if ($note->{'tie'} eq 'inter'){
    $noteXML->[$nseq]{'tie'}[0]               = { 'type' => 'stop'  };
    $noteXML->[$nseq]{'tie'}[1]               = { 'type' => 'start' };
    $noteXML->[$nseq]{'notations'}{'tied'}[0] = { 'type' => 'stop'  };
    $noteXML->[$nseq]{'notations'}{'tied'}[1] = { 'type' => 'start' };
  } elsif ($note->{'tie'} ne ''){  # start or stop
    $noteXML->[$nseq]{'tie'}               = { 'type' => $note->{'tie'} };
    $noteXML->[$nseq]{'notations'}{'tied'} = { 'type' => $note->{'tie'} };
  }

  if ($note->{lyricText} ne 'R'){
    # 歌詞をSJIS から UTF-8 に変換
    my $text = Unicode::Japanese->new($note->{lyricText}, 'sjis')->get;
    $noteXML->[$nseq]{'lyric'}    = { 'default-y' => "-77" };
    $noteXML->[$nseq]{'lyric'}{'text'}->content($text);
    $noteXML->[$nseq]{'lyric'}{'text'}->set_binary(0);
  } else {
    $noteXML->[$nseq]{'rest'}->set_node();
    $noteXML->[$nseq]{'pitch'}{'step'}  ->content('A');
    $noteXML->[$nseq]{'pitch'}{'octave'}->content(4);
  }

  # ３連符
  if ($note->{'time-modification'}){
    $noteXML->[$nseq]{'time-modification'}{'actual-notes'}->content(3);
    $noteXML->[$nseq]{'time-modification'}{'normal-notes'}->content(2);
    if ($note->{'time-modification'} eq 'begin'){
      $noteXML->[$nseq]{'beam'} = { 'number' => "1" };
      $noteXML->[$nseq]{'beam'}->content('begin');
      $noteXML->[$nseq]{'notations'}{'tuplet'} = { 'type' => "start",  'bracket' => "no" };
      $noteXML->[$nseq]{'notations'}{'tuplet'}->set_node();
    } elsif ($note->{'time-modification'} eq 'continue'){
      $noteXML->[$nseq]{'beam'} = { 'number' => "1" };
      $noteXML->[$nseq]{'beam'}->content('continue');
    } elsif ($note->{'time-modification'} eq 'end'){
      $noteXML->[$nseq]{'beam'} = { 'number' => "1" };
      $noteXML->[$nseq]{'beam'}->content('end');
      $noteXML->[$nseq]{'notations'}{'tuplet'} = { 'type' => "stop" };
      $noteXML->[$nseq]{'notations'}{'tuplet'}->set_node();
    }
  }

}

#------------------------------------------------------------------
# ustファイルを読み、xml生成に必要なデータを返す
#
sub readUst {
  my $inFile = $_[0];

  my @note = ();

  open (FID, $inFile) || die "error: can not open $inFile.\n";

  # ヘッダ部分
  while (<FID>){
    last if (/^\[#\d+\]/);

    s/(\r|\n)+//g;    # chomp
    my @data = split '=';

    $tempo = $data[1] if $data[0] eq 'Tempo';    # 大域変数tempoに値を保存
  }

  # 音符部分
  my $seq = 0;
  $note[$seq] = newNote();
  while (<FID>){
    last if (/^\[#NEXT\]/);
    s/(\r|\n)+//g;    # chomp
    my @data = split '=';
    
    if ($data[0] eq 'Length'){
      $note[$seq]->{duration}    = quantize($data[1]);
      length2note($note[$seq]);

    } elsif ($data[0] eq 'Lyric'){
      $note[$seq]->{lyricText}   = $data[1];

    } elsif ($data[0] eq 'NoteNum'){
      $note[$seq]->{pitchStep}   = noteNum2step  ($data[1]);
      $note[$seq]->{pitchOctave} = noteNum2octave($data[1]);
      $note[$seq]->{pitchAlter}  = noteNum2alter ($data[1]);

    } elsif ($data[0] =~ /^\[#\d+\]/){
      $seq++;
      $note[$seq] = newNote();
    }
  }

  close FID;

  # 結果出力
  return @note;
}

#------------------------------------------------------------------
# ustから得た一音符を保存するハッシュを作る
#
sub newNote {
  my %n = { duration    => 0,      # 音符長
            pitchStep   => 'C',    # 音の高さ
            pitchOctave => 4,      # 音の高さ
            pitchAlter  => 0,      # 1=#(半音上げ)
            type        => 'whole',# 音符記号
            lyricText   => '',     # モーラ
            dot         => 0,      # 1=付点あり
            tie         => '',     # start,stop,inter,''
  };
  return \%n;
}

#------------------------------------------------------------------
# 指定した一音符を複製する
#
sub copyNote {
  my ($org) = @_;
  my $new = newNote();
  foreach my $k (qw(duration pitchStep pitchOctave pitchAlter type lyricText dot tie)) {
    $new->{$k} = $org->{$k};
  }
  return $new;
}

#------------------------------------------------------------------
# UTAU ustのノート番号をキー名に変換する
#
sub noteNum2step {
  my $noteNum = $_[0];
  my @keyList = qw( C C D D E F F G G A A B );

  # noteNum=24 のとき C1
  return $keyList[$noteNum % 12];
}

#------------------------------------------------------------------
# UTAU ustのノート番号をオクターブ番号に変換する
#
sub noteNum2octave {
  my $noteNum = $_[0];

  # noteNum=24 のとき C1
  return int($noteNum / 12 - 1);
}

#------------------------------------------------------------------
# UTAU ustのノート番号を＃に変換する
#
sub noteNum2alter {
  my $noteNum = $_[0];
  my @alterList = qw( 0 1 0 1 0 0 1 0 1 0 1 0 );

  # noteNum=24 のとき C1
  return $alterList[$noteNum % 12];
}

#------------------------------------------------------------------
# UTAU ustのlengthを音符名に変換する
#
sub length2note {
  my ($note) = @_;
  my $length = $note->{'duration'};
  for (my $i = 0; $i < @lengthList; $i++){
    if ($length >= $lengthList[$i]){
      if ($typeList[$i] =~ /^(.+)?D$/) {
        $note->{'type'} = $1;
        my $tmp = $typeList[$i];
        $tmp =~ s/^.+?(D+)$/$1/;
        $note->{'dot'}  = length($tmp);
        $note->{'time-modification'}  = 0;
      } elsif ($typeList[$i] =~ /^(.+)?T$/) {
        $note->{'type'} = $1;
        $note->{'dot'}  = 0;
        $note->{'time-modification'}  = 1;
      } else {
        $note->{'type'} = $typeList[$i];
        $note->{'dot'}  = 0;
        $note->{'time-modification'}  = 0;
      }
      return;
    }
  }
  $note->{'type'} = 'whole';
  $note->{'dot'}  = 0;
  $note->{'time-modification'}  = 0;
}

#------------------------------------------------------------------
# 連続する休符を結合する
#
sub uniqR {
  my ($note) = @_;
  for (my $i = 1; $i < @$note; $i++){
    if ($note->[$i-1]->{'lyricText'} eq 'R' && $note->[$i]->{'lyricText'} eq 'R'){
      $note->[$i-1]->{'duration'} += $note->[$i]->{'duration'};
      splice (@$note, $i, 1);
      redo;
    }
  }
}

#------------------------------------------------------------------
# ３連符をまとめる
#
sub setTuplet {
  my ($note) = @_;
 
  my $tuplet = 0;
  for (my $i = 0; $i < @$note; $i++){
    if ($note->[$i]->{'time-modification'}){
      $tuplet++;
      if ($tuplet == 3){
        $note->[$i-2]->{'time-modification'} = "begin";
        $note->[$i-1]->{'time-modification'} = "continue";
        $note->[$i]  ->{'time-modification'} = "end";
        $tuplet = 0;
      }
    } else {
      $tuplet = 0;
    }
  }
}

#------------------------------------------------------------------
# 小節をまたぐ音符があれば分解してタイでつなぐ
#
sub setTie {
  my ($note, $measureLength) = @_;

  $len = 0;
  for (my $i = 0; $i < @$note; $i++){
    # 音符が小節をまたいでいれば、その音符を分解してタイでつなぐ
    if ($len + $note->[$i]->{'duration'} > $measureLength){
      my $new = copyNote($note->[$i]);
      if ($new->{'lyricText'} ne 'R'){
        if ($note->[$i]->{'tie'} eq ''){
          $note->[$i]->{'tie'} = 'start';
          $new       ->{'tie'} = 'stop';
        } elsif ($note->[$i]->{'tie'} eq 'stop'){
          $note->[$i]->{'tie'} = 'inter';
          $new       ->{'tie'} = 'stop';
        }
      }
      my $dur0 = $measureLength - $len;
      $note->[$i]->{'duration'} = $dur0;
      length2note($note->[$i]);
      $new->{'duration'} -= $dur0;
      length2note($new);
      $new->{'lyricText'} = 'ー' if ($new->{'lyricText'} ne 'R');
      splice (@$note, $i + 1, 0, $new);
      redo;

    } else {
      # 音符名と音長が一致しているかチェック
      my $l = 0;
      for ($l = 0; $l < @lengthList; $l++){
        last if ($note->[$i]->{'duration'} >= $lengthList[$l]);
      }
      if ($l < @lengthList && $note->[$i]->{'duration'} != $lengthList[$l]){
        # 音符名と音長が不一致なら音符を分解してタイでつなぐ
        my $new = copyNote($note->[$i]);
        if ($note->[$i]->{'tie'} eq ''){
          $note->[$i]->{'tie'} = 'start';
          $new       ->{'tie'} = 'stop';
        } elsif ($note->[$i]->{'tie'} eq 'stop'){
          $note->[$i]->{'tie'} = 'inter';
          $new       ->{'tie'} = 'stop';
        }
        my $dur0 = $lengthList[$l];
        $note->[$i]->{'duration'} = $dur0;
        length2note($note->[$i]);
        $new->{'duration'} -= $dur0;
        length2note($new);
        $new->{'lyricText'} = 'ー';
        splice (@$note, $i + 1, 0, $new);
        redo;

      } else {
        # 音符名に問題がなく、小節もまたいでいない場合
        $len = ($len + $note->[$i]->{'duration'}) % $measureLength;
      }
    }
  }
  # もし最後の小節に拍数ぴったりのデータが入っていない場合は休符を挿入する。
  if ($len < $measureLength){
    my $new = copyNote($note->[-1]);
    $new->{'lyricText'} = 'R';
    $new->{'duration'}  = $measureLength - $len;
    length2note($new);
    push @$note, $new;
  }
}

#------------------------------------------------------------------
# 一の位を四捨五入する
#
sub quantize {
  return int(($_[0] + 5) / 10) * 10;
}

