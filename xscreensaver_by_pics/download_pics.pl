#!/usr/bin/perl 
use strict; # Good practice 
use warnings; # Good practice 
use LWP::Simple; # From CPAN 
use JSON qw( decode_json ); # From CPAN 
use Data::Dumper; # Perl core module 
use File::Path qw(make_path remove_tree); 
use POSIX qw(strftime);
use Getopt::Long;


### get options 
my $url = 'http://localhost:8000/online_pics.json'; 
my $save_to = "$ENV{HOME}/xscreensaver_by_pics/result_data";
my $random_delay = 10;
my $verbose = 0;
my $help  = 0; 
my $result = GetOptions(
   "json_url=s" => \$url,#string
   "save_to=s" => \$save_to,#string
   "random_delay=i" => \$random_delay,#integer
   "verbose"   => \$verbose,#flag
   "quiet"     => sub { $verbose = 0 },
   "help|?"    => \$help
);
if(!$result){ print STDERR "parameters error\n"; exit 1;}


### random delay
if($random_delay > 0){
  my $seconds = $random_delay * 60;
  my $random = rand($random_delay);
  sleep($random);
}


### check parameters
if(!-e "$save_to"){
 my $err;
 make_path("$save_to",{error => \$err});
 if($err){ print STDERR "$err\n"; exit 1; }
}
my $save_to_current = "$save_to/current";
my $save_to_default = "$save_to/default";
if(!-e "$save_to_current") { make_path("$save_to_current");}
if(!-e "$save_to_default") { make_path("$save_to_default");}


### start time
my $log_file = "$save_to/download.log";
open(my $fh, "+>", "$log_file"); 
my $start_time = strftime "%Y-%m-%d %H:%M:%S", localtime;
&log( "start time: $start_time\n" );


### get json
my $json = get($url);
die "Could not get $url!" unless defined $json;
my $decoded_json = decode_json( $json );


### get image list
my $version = 0;
my $version_old = 0;
my $img_list = [];
my $img_default = [];
$version = $decoded_json->{"version"};
$img_list = $decoded_json->{"image_list"};
$img_default = $decoded_json->{"image_default"};
if ( ! defined($version) || !defined($img_list) || !defined($img_default)){
  &log( "json format error\n" );
  end(1);
}


### check if need download
&log( "latest version is $version\n" );
my $version_file = "$save_to/version_file";
#$version_old = get_current_version();
&log( "old version is $version_old\n" );
if($version eq '' or $version <= $version_old){
  &log( "no new version was found.\n" );
  end(0);
}

### download pics
download_pics($img_list,$save_to_current);
download_pics($img_default,$save_to_default);


### end
end(0);


### common functions
sub download_pic{
  my ($img,$filename) = @_;
  my $rc = getstore($img, $filename);
  if (is_error($rc)) {
    return 0, "download <$img> failed with $rc";
  }else{
    return 1, "download $img successfully to $filename\n";
  }
}
sub download_pics{
  my ($img_list,$save_to) = @_;
  my $i = 0;
  my $dr = 1; # suceesful
  for my $img (@$img_list){
    my $filename = "$save_to/$i".".jpg";
    my ($r, $m) = download_pic($img,$filename);
    &log($m);
    $i++;
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
}

sub get_current_version(){
  if(!-e "$version_file") { return -1;}
  open(my $f, '<', $version);
  if(!defined($f)){ 
    &log("Could not open file '$version_file' with the error $!");
    return -1;
  }
  while (my $row = <$fh>) {
  chomp $row;
  if(defined($row) && $row >=0 ){ close($f);return $row;}
  }
  close($fh);
  return -1;
}
sub save_current_version($){
 my $version = shift;
 open(my $f, "+>", "$version_file");
 if(!defined($f)){
   &log("Error:failed to save version.\n");
   return;
 }
 print $f "$version";
 close($f);
}
 
