#!/usr/bin/perl
#
# utau2sinsy - ust(of UTAU)-MusicXML(for Sinsy) converter
#
#            - UTAU��ust�t�@�C����ǂݍ��� Sinsy �p�� MusicXML ���o�͂���B
#
#
# ���g�p���@����1 �`WSL��R�}���h�v�����v�g�Ŏg�p��
#
#   XML::Smart �� Unicode::Japanese ���W���[�����C���X�g�[��������ŁA
#   �ȉ��̗l�Ɏ��s���ĉ������B
#     % perl ./utau2sinsy.pl ./sample.ust
#
#     �����W���[���C���X�g�[���̗�(cygwin)
#         > perl -MCPAN -e shell
#         cpan> install XML::Smart
#         cpan> install Unicode::Japanese
#         cpan> exit
#     �����W���[���C���X�g�[���̗�(activetcl)
#         > ppm install XML::Smart
#         > ppm install XML::Smart
#
#   sample.ust �Ɠ����t�H���_�� sample.xml �Ƃ������ʃt�@�C��������܂��B
#   ����� Sinsy (http://www.sinsy.jp/) �ɗ^���ĉ������B
#
#   ���W���[���������ꍇ�A�K�v�Ǝv���郂�W���[����lib/�ȉ��ɃR�s�[���Ă���܂��̂�
#   �ȉ��̂悤�Ɏ��s���Ă݂ĉ�����(���ɂ���Ă͂��܂������Ȃ���������܂���)�B
#
#     % perl -I./lib ./utau2sinsy.pl ./sample.ust
#
# �����ӎ�����
#
#   ���ʃt�@�C���Ɠ����̃t�@�C�������ɑ��݂��Ă���ꍇ�A���f�ŏ㏑�����܂��B
#   �����Ӊ������B
#
#   �{�t�@�C���� shift-jis �ŕۑ����ĉ������B
#
#   �ėp�I�� MusicXML �̏o�͂ł͂Ȃ��A�����܂Ō����_(2010/05/02����)��
#   Sinsy �������ł�����x�� XML ���o�͂��܂��B
#   ��҂� MusicXML �ɂ��Ă̏ڂ����m���͎������킹�Ă��܂���B
#   ���ʕ\���ɂ��Ă� ���̂Ƃ��� MuseScore(http://www.musescore.org/)��
#   �\���m�F���Ă��܂��B
#
#   �����؂̕��������邩������܂���B
#   UTAU��stp�p�����[�^��s�b�`�Ȃǂ͔��f����܂���B
#   �e�����̍����A�����A�����݂̂���XML�𐶐����Ă��܂��B
#
# �����C�Z���X��
#
#   cygwin-perl�̃��C�u�������Ĕz�z���Ă��܂��̂ŁA
#   �{�X�N���v�g��cygwin�̃��C�Z���X�Ɠ���GPL���C�Z���X�Ƃ��Ă��g���������B
#
# ���ύX�L�^��
#
#   2011/05/06 ver.0.16
#     - �e���v���[�gXML�̃t�@�C�����ԈႢ���C�������B
#   2010/09/14 ver.0.15
#     - �R�A���ɑΉ������i���������G�ȍ\���̘A���ł͎��s���邩���j�B
#     - MuseScore���e���|����F���A�ύX�ł���悤�ɂ����B
#     - �x�����A�������ꍇ�͂P�ɂ܂Ƃ߂�悤�ɂ����B
#     - �Ō�̏��߂ɂ���̗ǂ��x���������Ă��Ȃ��ꍇ�͑}������悤�ɂ����B
#   2010/05/04 ver.0.14
#     - ��I�N�^�[�u�𒴂���^�C�ɑΉ�
#     - �x���̉��̍�����C4�ɂ���
#     - �������̈�̈ʂ��l�̌ܓ�����i�ȈՃN�I���^�C�Y�j
#   2010/01/13 ver.0.13
#     - ��d�t�_�����ɑΉ�
#   2010/01/13 ver.0.12
#     - XML::Smart���W���[����xml��������悤�ɂ����B
#     - XML�̃e���v���[�g��ǂނ悤�ɂ����B
#     - ���߂��܂��������ɑΉ�(�������ă^�C�łȂ�)�B
#     - �t�_�����ɑΉ�
#   2010/01/08 ver.0.11
#     - MuseScore�ł�����x�y���\�������悤�ɂ����B�܂��s������X����܂��B
#     - UTF-8 �ŏo�͂���悤�ɂ����B
#     - �^�O�̒����ɉ����ĉ��s�R�[�h����ꂽ�����Ȃ������肷��悤�ɂ����B
#   2010/01/06 ver.0.1 ���J


# ���ȉ��̍s�́Acygwin��perl�Ŏ��s���A���K�v�ȃ��W���[�����C���X�g�[�����Ă��Ȃ�
#   �ꍇ�Ɍ���L���ɂ��邱�ƁB
#use lib './lib';

#use strict;
use Unicode::Japanese;
use XML::Smart;
use File::Basename;


#------------------------------------------------------------------
# �ϐ��ݒ�Ȃ�
# 

my $appname = 'utau2sinsy.pl';
my $version = '0.16';
my $encoding = 'UTF-8';
my $appDir = dirname($0);
my $templeteFile = "$appDir/template.xml";

# ���ϐ�
our $tempo     = 100;  # �e���|
our $divisions = 480;  # �l�������̕���\
our $beats     = 4;    # ���q
our $beatType  = 4;    # ������..
our $useTie    = 1;    # 1=���������ߋ�؂���܂����ۓ��Ƀ^�C���g��

# ���t�_�����ɂ͉�����������D�����Ă���B
our @lengthList = qw( 1920    1680     1440   960     840       720      480     420
                      360     320      240    210     180       160      120     105      90      80     60   
                      52.5    45       30     26.25   22.5      15       13.125  11.25  7.5);
our @typeList   = qw( whole   halfDD   halfD  half    quarterDD quarterD quarter eighthDD
                      eighthD quarterT eighth 16thDD  16thD     eighthT  16th    32ndDD   32ndD   16thT  32nd 
                      64thDD  64thD    64th   128thDD 128thD    128th    256thDD 256thD 256th);

#------------------------------------------------------------------
# �����`�F�b�N
#
if (@ARGV < 2){
  print "error: syntax error\n\n";
  print "usage: $0 ustFile xmlfile \n";
  
  exit 1;
}

## Windows�`���̕\���Ȃ�cygwin(unix)�`���ɂ���
#if ($ARGV[0] =~ /\\/){
#  $ARGV[0] =~ s/^([a-zA-Z]):/\/cygdrive\/$1/;
#  $ARGV[0] =~ s/\\/\//g;
#}

my $inFile = $ARGV[0];

# ���ʏo�̓t�@�C�������쐬
my $outFile = $ARGV[1];
# $outFile =~ s/ust$/xml/;

# ���s�����擾
my @ltime = localtime(time);
my $encodeDate = sprintf ("%04d-%02d-%02d", $ltime[5]+1900,$ltime[4]+1,$ltime[3]);

#------------------------------------------------------------------
#
# �{��
#
my $XML = XML::Smart->new($templeteFile);
my $enc = $XML->{'score-partwise'}{'identification'}{'encoding'};
$enc->{'software'}->content("$appname version $version");
$enc->{'encoding-date'}->content($encodeDate);

# ust�t�@�C����ǂ݁A�e���|�A�����f�[�^���擾
my @note = readUst($inFile);

# �P���߂̒������v�Z
my $measureLength = $divisions * $beats / ($beatType / 4);

# �e���|�┏�q��ݒ肷��
my $measure = $XML->{'score-partwise'}{'part'}{'measure'};
$measure->{'direction'}{'sound'} = { 'tempo' => $tempo };
$measure->{'attributes'}{'divisions'}->content($divisions);
$measure->{'attributes'}{'time'}{'beats'}->content($beats);
$measure->{'attributes'}{'time'}{'beat-type'}->content($beatType);

# �A���x������������
uniqR (\@note);

# �^�C��ݒ肷��
setTie (\@note, $measureLength) if $useTie;

# 3�A�����܂Ƃ߂�
setTuplet (\@note);

# �����f�[�^��ݒ肷��
my $len = 0;
my $mseq = 0;     # measure ��*�z��*�ԍ�
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

# �o��
$XML->save($outFile);

#print "-------- �ϊ��I�� --------\n";
#print "���̓t�@�C��= $inFile\n�o�̓t�@�C��= $outFile\n";
#print "-- ENTER �������ĉ����� --\n";
print "-------- Convert Success --------\n";
print "$inFile -----> $outFile\n";

#-------------------------------------------------------
# �ꉹ���̃^�O��ǋL
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
    # �̎���SJIS ���� UTF-8 �ɕϊ�
    my $text = Unicode::Japanese->new($note->{lyricText}, 'sjis')->get;
    $noteXML->[$nseq]{'lyric'}    = { 'default-y' => "-77" };
    $noteXML->[$nseq]{'lyric'}{'text'}->content($text);
    $noteXML->[$nseq]{'lyric'}{'text'}->set_binary(0);
  } else {
    $noteXML->[$nseq]{'rest'}->set_node();
    $noteXML->[$nseq]{'pitch'}{'step'}  ->content('A');
    $noteXML->[$nseq]{'pitch'}{'octave'}->content(4);
  }

  # �R�A��
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
# ust�t�@�C����ǂ݁Axml�����ɕK�v�ȃf�[�^��Ԃ�
#
sub readUst {
  my $inFile = $_[0];

  my @note = ();

  open (FID, $inFile) || die "error: can not open $inFile.\n";

  # �w�b�_����
  while (<FID>){
    last if (/^\[#\d+\]/);

    s/(\r|\n)+//g;    # chomp
    my @data = split '=';

    $tempo = $data[1] if $data[0] eq 'Tempo';    # ���ϐ�tempo�ɒl��ۑ�
  }

  # ��������
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

  # ���ʏo��
  return @note;
}

#------------------------------------------------------------------
# ust���瓾���ꉹ����ۑ�����n�b�V�������
#
sub newNote {
  my %n = { duration    => 0,      # ������
            pitchStep   => 'C',    # ���̍���
            pitchOctave => 4,      # ���̍���
            pitchAlter  => 0,      # 1=#(�����グ)
            type        => 'whole',# �����L��
            lyricText   => '',     # ���[��
            dot         => 0,      # 1=�t�_����
            tie         => '',     # start,stop,inter,''
  };
  return \%n;
}

#------------------------------------------------------------------
# �w�肵���ꉹ���𕡐�����
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
# UTAU ust�̃m�[�g�ԍ����L�[���ɕϊ�����
#
sub noteNum2step {
  my $noteNum = $_[0];
  my @keyList = qw( C C D D E F F G G A A B );

  # noteNum=24 �̂Ƃ� C1
  return $keyList[$noteNum % 12];
}

#------------------------------------------------------------------
# UTAU ust�̃m�[�g�ԍ����I�N�^�[�u�ԍ��ɕϊ�����
#
sub noteNum2octave {
  my $noteNum = $_[0];

  # noteNum=24 �̂Ƃ� C1
  return int($noteNum / 12 - 1);
}

#------------------------------------------------------------------
# UTAU ust�̃m�[�g�ԍ������ɕϊ�����
#
sub noteNum2alter {
  my $noteNum = $_[0];
  my @alterList = qw( 0 1 0 1 0 0 1 0 1 0 1 0 );

  # noteNum=24 �̂Ƃ� C1
  return $alterList[$noteNum % 12];
}

#------------------------------------------------------------------
# UTAU ust��length���������ɕϊ�����
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
# �A������x������������
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
# �R�A�����܂Ƃ߂�
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
# ���߂��܂�������������Ε������ă^�C�łȂ�
#
sub setTie {
  my ($note, $measureLength) = @_;

  $len = 0;
  for (my $i = 0; $i < @$note; $i++){
    # ���������߂��܂����ł���΁A���̉����𕪉����ă^�C�łȂ�
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
      $new->{'lyricText'} = '�[' if ($new->{'lyricText'} ne 'R');
      splice (@$note, $i + 1, 0, $new);
      redo;

    } else {
      # �������Ɖ�������v���Ă��邩�`�F�b�N
      my $l = 0;
      for ($l = 0; $l < @lengthList; $l++){
        last if ($note->[$i]->{'duration'} >= $lengthList[$l]);
      }
      if ($l < @lengthList && $note->[$i]->{'duration'} != $lengthList[$l]){
        # �������Ɖ������s��v�Ȃ特���𕪉����ă^�C�łȂ�
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
        $new->{'lyricText'} = '�[';
        splice (@$note, $i + 1, 0, $new);
        redo;

      } else {
        # �������ɖ�肪�Ȃ��A���߂��܂����ł��Ȃ��ꍇ
        $len = ($len + $note->[$i]->{'duration'}) % $measureLength;
      }
    }
  }
  # �����Ō�̏��߂ɔ����҂�����̃f�[�^�������Ă��Ȃ��ꍇ�͋x����}������B
  if ($len < $measureLength){
    my $new = copyNote($note->[-1]);
    $new->{'lyricText'} = 'R';
    $new->{'duration'}  = $measureLength - $len;
    length2note($new);
    push @$note, $new;
  }
}

#------------------------------------------------------------------
# ��̈ʂ��l�̌ܓ�����
#
sub quantize {
  return int(($_[0] + 5) / 10) * 10;
}

