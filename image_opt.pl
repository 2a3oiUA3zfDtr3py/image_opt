#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use bytes();
use File::Find;
use Parallel::ForkManager;

setpriority(0, 0, 19);
my ($pm, $parallel_quantity, $directories_to_search, $working_dir, $solt, $report, $report_str, $i, @jpegtran_options, $jpeg_optimize_flag);
my ($png_fast1_flag, $png_fast2_flag);
$parallel_quantity = &execute_command("cat /proc/cpuinfo 2>&1 | grep processor | wc -l") + 0;
@jpegtran_options = ('','-arithmetic');
$jpeg_optimize_flag = 0;
$png_fast1_flag = 0;
$png_fast2_flag = 0;
my ($P_jpegoptim,$P_removeapp0,$P_jpegtran,$P_optipng,$P_convert,$P_gif2apng,$P_apng2gif,$P_zopflipng,$P_advpng);
$P_jpegoptim  = 'jpegoptim';
$P_removeapp0 = 'removeapp0';
$P_jpegtran   = 'jpegtran';
$P_optipng    = 'optipng';
$P_convert    = 'convert';
$P_gif2apng   = 'gif2apng';
$P_apng2gif   = 'apng2gif';
$P_zopflipng  = 'zopflipng';
$P_advpng     = 'advpng';

for($i = 0;$i < @ARGV;$i++) {
	if($ARGV[$i] =~ /^-([1-9][0-9]*)$/) {
		$parallel_quantity = $1 + 0;
	} elsif($ARGV[$i] =~ /^-arithmetic$/) {
		$jpeg_optimize_flag = 1;
	} elsif($ARGV[$i] =~ /^-fast$/) {
		$png_fast1_flag = 1;
	} elsif($ARGV[$i] =~ /^-fast2$/) {
		$png_fast2_flag = 1;
	} else {
		exit;
	}
}

$solt = getRandomCharacters(180);
$working_dir = &char_escape("/dev/shm/" . getRandomCharacters(120));
$report = $working_dir . '/' . &char_escape(getRandomCharacters(120) . ".txt");
&execute_command("mkdir -p $working_dir");
&execute_command("echo \"\" >> $report");

if(!$parallel_quantity) {
	$parallel_quantity++;
}
$pm = Parallel::ForkManager->new($parallel_quantity);
$directories_to_search = './';
find(sub {
	my ($file, $mime, $file_name_length);
	$file = &char_escape($_);
	$mime = &execute_command("mimetype -b -M ./$file");
	$file_name_length = bytes::length($_);

	if ($mime =~ /^image\/(jpeg|png|gif|bmp|tiff|x-tiff).*$/ || $mime =~ /^image\/x-portable-(bit|gray|any|pix)map.*$/) {
		$pm->start and return;
		my (@temp_file,@hash);
		$temp_file[0] = &getStringHash($File::Find::name . $solt);

		if ($mime =~ /^image\/jpeg.*$/) {
			$temp_file[1] = $working_dir . '/' . $temp_file[0] . '1.jpg';
			$temp_file[2] = $working_dir . '/' . $temp_file[0] . '2.jpg';
			&execute_command("cp ./$file $temp_file[1]");
			&execute_command("$P_jpegoptim --strip-all --all-progressive -f $temp_file[1]");
			&execute_command("cp $temp_file[1] $temp_file[2]");
			$hash[0] = &getImageHash($temp_file[1]);
			&execute_command("$P_jpegtran " . $jpegtran_options[$jpeg_optimize_flag ^ 0x01] . " -outfile $temp_file[1] $temp_file[1]");
			&execute_command("$P_removeapp0 $temp_file[1]");
			&execute_command("$P_jpegoptim --strip-all --all-normal -f $temp_file[1]");
			&execute_command("$P_jpegtran " . $jpegtran_options[$jpeg_optimize_flag] . " -outfile $temp_file[1] $temp_file[1]");
			$hash[1] = &getImageHash($temp_file[1]);
			if ($hash[0] ne $hash[1]) {
				&execute_command("cp $temp_file[2] $temp_file[1]");
				&execute_command("$P_jpegtran " . $jpegtran_options[$jpeg_optimize_flag] . " -outfile $temp_file[1] $temp_file[1]");
			} else {
				&execute_command("$P_removeapp0 $temp_file[1]");
			}
			&execute_command("cp $temp_file[1] ./$file");
			&execute_command("rm $temp_file[1]");
			&execute_command("rm $temp_file[2]");
		} elsif ($mime =~ /^image\/png.*$/) {
			$temp_file[1] = $working_dir . '/' . $temp_file[0] . '1.png';
			$temp_file[2] = $working_dir . '/' . $temp_file[0] . '2.pam';
			&execute_command("cp ./$file $temp_file[1]");
			if (&execute_command("$P_optipng -snip -simulate -o0 $temp_file[1] 2>&1 | head -n 2 | sed -e \"1d\"") !~ /^Importing APNG.*$/) {
				&execute_command("$P_convert $temp_file[1] $temp_file[2]");
				&execute_command("rm $temp_file[1]");
				&execute_command("$P_convert $temp_file[2] $temp_file[1]");
				&execute_command("rm $temp_file[2]");
				if(&optimize_png($temp_file[1])) {
					&execute_command("echo \"zopflipng $file\" >> $report");
				}
				&execute_command("cp $temp_file[1] ./$file");
			} else {
				&execute_command("echo \"APNG $file\" >> $report");
			}
			&execute_command("rm $temp_file[1]");
		} elsif ($mime =~ /^image\/x-portable-(bit|gray|any|pix)map.*$/ || $mime =~ /^image\/(bmp|tiff|x-tiff).*$/) {
			if($file_name_length < 200) {
				$temp_file[1] = $working_dir . '/' . $temp_file[0] . '.png';
				$temp_file[2] = $file . &char_escape(&getRandomCharacters(32) . '.png');
				&execute_command("$P_convert -set colorspace RGB ./$file $temp_file[1]");
				if(&optimize_png($temp_file[1])) {
					&execute_command("echo \"zopflipng $file\" >> $report");
				}
				system("cp $temp_file[1] ./$temp_file[2]");
				system("rm $temp_file[1]");
			} else {
				&execute_command("echo \"$file\" >> $report");
			}
		} elsif ($mime =~ /^image\/gif*$/) {
			$temp_file[1] = $temp_file[0] . '.png';
			$temp_file[2] = $temp_file[0] . '.gif';
			&execute_command("cp ./$file $temp_file[2]");
			&execute_command("$P_gif2apng $temp_file[2]");
			&execute_command("$P_apng2gif $temp_file[1]");
			&execute_command("rm $temp_file[1]");
			&execute_command("rm ./$file");
			&execute_command("cp $temp_file[2] ./$file");
			&execute_command("rm $temp_file[2]");
		}
		$pm->finish;
	} elsif ($mime =~ /^image\/.*$/) {
		$mime =~ s/\n//;
		&execute_command("echo \"$mime  $file\" >> $report");
	}
}, $directories_to_search);
$pm->wait_all_children;

print &execute_command("cat $report | sort");
if(bytes::length($working_dir) == 129) {
	&execute_command("rm -rf $working_dir/");
}

sub optimize_png {
	my ($target_file) = @_;
	my (@hash,$temp_file,$return_code);
	$return_code = 0;
	$temp_file = $working_dir . '/' . &char_escape(&getStringHash($target_file . 'optimize_png' . $solt) . '.png');

	&execute_command("$P_optipng -zc9 -zm9 -zs0-3 -f0-5 -zw32k -strip all $target_file");
	if($png_fast1_flag == 1) {
		return $return_code;
	}
	&execute_command("cp $target_file $temp_file");
	$hash[0] = &getImageHash($target_file);
	if ($png_fast2_flag == 1) {
		&execute_command("$P_zopflipng -y --iterations=5 --splitting=3 --filters=ep $target_file $target_file");
	} else {
		&execute_command("$P_zopflipng -y --iterations=15 --splitting=3 --filters=empb $target_file $target_file");
	}
	$hash[1] = &getImageHash($target_file);
	if($hash[0] ne $hash[1]) {
		&execute_command("rm $target_file");
		&execute_command("cp $temp_file $target_file");
		&execute_command("$P_advpng -z -4 -i 15 $target_file");
		$return_code = 127;
	}
	&execute_command("rm $temp_file");
	return $return_code;
}

sub getImageHash {
	my ($file) = @_;
	my ($temp,$temp_file);
	$temp_file = $working_dir . '/' . &char_escape(&getStringHash($file . 'getImageHash' . $solt) . '.rgba');
	&execute_command("$P_convert $file -set colorspace sRGB -type TrueColorMatte $temp_file");
	$temp = &execute_command("sha512sum $temp_file");
	&execute_command("rm $temp_file");
	$temp =~ s"\n" "g;
	$temp =~ s"(^[^ ]*)\ .*"$1"g;
	return $temp;
}

sub getStringHash {
	my ($str) = @_;
	my ($temp,$escaped_str);
	$escaped_str = &char_escape($str);
	$temp = '';
	open(IN,"echo \"$escaped_str\" | sha512sum |");
	while(<IN>) {
		$temp .= $_;
	}
	$temp =~ s"\n" "g;
	$temp =~ s"(^[^ ]*) .*"$1"g;
	return $temp;
}

sub getRandomCharacters {
	my ($length) = @_;
	my ($str,$c_length,$flag);
	if($length % 4 == 0) {
		$c_length = $length / 4;
		$flag = 1;
	} else {
		$c_length = 1 + ($length - ($length % 4)) / 4;
		$flag = 0;
	}
	$c_length *= 3;
	$str = '';
	open(IN,"head -c $c_length /dev/urandom | base64 --wrap=0 |");
	while(<IN>) {
		$str .= $_;
	}
	close(IN);
	$str =~ s"(^[^\n]*)\n.*"$1"g;
	$str =~ s"/"-"g;
	if($flag) {
		return $str;
	} else {
		return substr($str,0,$length);
	}
}

sub execute_command {
	my ($command) = @_;
	my ($temp);
	$temp = "";
	open(IN,"echo \"\$($command  2>&1 )\" |");
	while(<IN>) {
		$temp .= $_;
	}
	close(IN);
	return $temp;
}

sub char_escape {
	my ($escaped_filename) = @_;
	$escaped_filename =~ s'\\'\\\\'g;
	$escaped_filename =~ s"\n"\\\n"g;
	$escaped_filename =~ s'\"'\\"'g;
	$escaped_filename =~ s'\?'\\?'g;
	$escaped_filename =~ s'\#'\\#'g;
	$escaped_filename =~ s'\!'\\!'g;
	$escaped_filename =~ s'\&'\\&'g;
	$escaped_filename =~ s'\$'\\$'g;
	$escaped_filename =~ s'\='\\='g;
	$escaped_filename =~ s'\['\\['g;
	$escaped_filename =~ s'\]'\\]'g;
	$escaped_filename =~ s'\)'\\)'g;
	$escaped_filename =~ s'\('\\('g;
	$escaped_filename =~ s'\|'\\|'g;
	$escaped_filename =~ s'\*'\\*'g;
	$escaped_filename =~ s'\}'\\}'g;
	$escaped_filename =~ s'\{'\\{'g;
	$escaped_filename =~ s'\>'\\>'g;
	$escaped_filename =~ s'\<'\\<'g;
	$escaped_filename =~ s'\`'\\`'g;
	$escaped_filename =~ s'\:'\\:'g;
	$escaped_filename =~ s'\;'\\;'g;
	$escaped_filename =~ s'\,'\\,'g;
	$escaped_filename =~ s'\ '\\ 'g;
	$escaped_filename =~ s"\'"\\'"g;
	return $escaped_filename;
}
