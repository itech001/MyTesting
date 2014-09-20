#!/usr/bin/perl 

use strict; # Good practice 
use warnings; # Good practice 
use LWP::Simple; # From CPAN 
use JSON qw( decode_json ); # From CPAN 
use Data::Dumper; # Perl core module 
use File::Path qw(make_path remove_tree); 
use POSIX qw(strftime);
use Getopt::Long;
use Data::GUID;
use File::Basename;
use Sys::HostAddr;
use Fcntl ':flock';


### get options 
my $url = 'http://localhost:8000/online_pics.json'; 
my $save_to = "$ENV{HOME}/xscreensaver_by_pics/result_data";
my $random_delay = 1;
my $verbose = 0;
my $help  = 0; 
my $debug = 0;
my $result = GetOptions(
   "json_url=s" => \$url,#string
   "save_to=s" => \$save_to,#string
   "random_delay=i" => \$random_delay,#integer
   "verbose"   => \$verbose,#flag
   "quiet"     => sub { $verbose = 0 },
   "debug"     => \$debug,
   "help|?"    => \$help
);
if(!$result){ print STDERR "parameters error\n"; exit 1;}


### check parameters
if(!-e "$save_to"){
 my $err;
 make_path("$save_to",{error => \$err});
 if(!$err){ print STDERR "$err\n"; exit 1; }
}
my $save_to_current = "$save_to/current";
my $save_to_default = "$save_to/default";
my $save_to_used = "$save_to/used";
if(!-e "$save_to_current") { make_path("$save_to_current");}
if(!-e "$save_to_default") { make_path("$save_to_default");}

my $sysaddr = Sys::HostAddr->new();
my $log_name = $sysaddr->main_ip();
my $log_file = "$save_to/.${log_name}.log";
open(my $fh, "+>", "$log_file");
if(!$fh){ print STDERR "failed to open log file $log_file\n";}

if($debug){
  &log("url:$url\n");
  &log("save to:$save_to\n");
  &log("max delay:$random_delay\n");
}


### random delay
my $start_time = strftime "%Y-%m-%d %H:%M:%S", localtime;
&log( "start time: $start_time\n" );
if($random_delay > 0){
  my $seconds = $random_delay * 60;
  my $random = rand($seconds);
  &log("delay $random seconds\n");
  sleep($random);
}


### start time
my $start_time_delay = strftime "%Y-%m-%d %H:%M:%S", localtime;
&log( "start time after delay: $start_time_delay\n" );


### get json
my $json = get($url);
if(! defined($json)){
 &log_error("cannot get json with the error $!\n");
 end(1);
}
my $decoded_json = decode_json( $json );
&log( Dumper $decoded_json);

### get image list
my $version = 0;
my $version_old = 0;
my $img_list = [];
my $img_default = [];
$version = $decoded_json->{"version"};
$img_list = $decoded_json->{"image_list"};
$img_default = $decoded_json->{"image_default"};
if ( ! defined($version) || !defined($img_list) || !defined($img_default)){
  &log_error( "json format error\n" );
  end(1);
}


### check if need download
&log( "latest version is $version\n" );
my $version_file = "$save_to/.version_file";
$version_old = &get_current_version();
&log( "old version is $version_old\n" );
if($version eq '' or $version <= $version_old){
  &log( "no new version was found.\n" );
  end(0);
}


### download pics
my $r = 1;
$r = download_pics($img_list,$save_to_current,1);
if(!$r){
  &save_current_version($version);
  end(0);
}

$r = download_pics($img_default,$save_to_default,1);

### end
end(0);


### common functions
sub download_pic{
  my ($img,$filename) = @_;
  my $rc = getstore($img, $filename);
  if (is_error($rc)) {
    return 1, "download <$img> failed with $rc";
  }else{
    return 0, "download $img successfully to $filename\n";
  }
}
sub download_pics{
  my ($img_list,$save_to,$is_update_used_link) = @_;
  my $guid = Data::GUID->new;
  my $tmp = $guid->as_string; 
  my $save_to_tmp = dirname($save_to) . '/' . $tmp;
  if(!-e "$save_to_tmp") { make_path("$save_to_tmp");}
  my $i = 0;
  my $s = 0; # suceesful
  for my $img (@$img_list){
    my $filename = "$save_to_tmp/$i".".jpg";
    my ($r, $m) = download_pic($img,$filename);
    &log($m);
    if(!$r){ $s++;} 
    $i++;
  }
  if($s > 0){
    &log("remove ${save_to}.bak\n");
    remove_tree("${save_to}.bak");
    #system("rm -rf ${save_to}.bak");
    &log("rename from $save_to to ${save_to}.bak\n");
    rename($save_to, "${save_to}.bak");
    #system("mv $save_to ${save_to}.bak");
    &log("rename from $save_to_tmp to $save_to\n");
    rename($save_to_tmp,$save_to);
    #system("mv $save_to_tmp $save_to");
    if($is_update_used_link){
      &log("symlink from $save_to to $save_to_used\n");
      symlink($save_to, $save_to_used);  
      #system("ln -s $save_to $save_to_used");
    }
    return 0;
  }else{
    return 1;
  }
}

sub end{
  my $code = shift;
  my $end_time = strftime "%Y-%m-%d %H:%M:%S", localtime;;
  &log("end time: $end_time\n");
  close $fh;
  exit $code;
}
sub log{
  my $msg = shift;
  print $fh $msg if defined $fh;
  if($debug){print $msg;}
}
sub log_error{
  my $msg = shift;
  print $fh $msg if defined $fh;
  if($debug){print STDERR $msg;}
}
sub get_current_version(){
  if(!-e "$version_file") { return -1;}
  open(my $f, '<', $version_file);
  if(!defined($f)){ 
    &log("Could not open file '$version_file' with the error $!");
    return -1;
  }
  while (my $row = <$f>) {
  chomp $row;
  if(defined($row) && $row >=0 ){ close($f);return $row;}
  }
  close($f);
  return -1;
}
sub save_current_version($){
 my $version = shift;
 open(my $f, "+>", "$version_file");
 if(!defined($f)){
   &log("Error:failed to save version.\n");
   return;
 }
 flock($f, LOCK_EX);
 print $f "$version";
 close($f);
}
 
