#!/usr/bin/env perl5

use strict;
use warnings;
use utf8;
use Net::Twitter;
use Encode;
use JSON;
use Config::Pit;
use Unicode::EastAsianWidth;

my $conf = pit_get('twitter.com',
	requires => {
		consumer_key => "consumer_key",
		consumer_secret => "consumer_secret",
		token => "token",
		token_secret => "token_secret",
	}
);

#my $tw = Net::Twitter->new(
	#traits				=> [qw/OAuth API::REST/],
	#consumer_key		=> $conf->{consumer_key},
	#consumer_secret		=> $conf->{cunsumer_secret},
	#access_token		=> $conf->{token},
	#access_token_secret	=> $conf->{token_secret},
#);

# test用
my $tw = Net::Twitter->new(
	traits				=> [qw/OAuth API::REST/],
	consumer_key		=> $conf->{consumer_key},
	consumer_secret		=> $conf->{consumer_secret},
	access_token		=> $conf->{token},
	access_token_secret	=> $conf->{token_secret},
);

my %month = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6, Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12 );

my $home_dir = '.';
my $id_file = "$home_dir/since_id.log";
check_datafile($id_file);
my $since_id = get_since_id($id_file);

my $data = $tw->friends_timeline({ since_id => $since_id, count => 100 });

my $logged_id = $$data[0]->{'id'};

for (reverse @$data) {
	my $user = $_->{'user'}{'screen_name'};
	my $name = encode_utf8($_->{'user'}{'name'});
	my $text = encode_utf8($_->{'text'});
	my @day = split(/ /, $_->{'created_at'});

	my $name_length = length($user) + v_length($_->{'user'}{'name'});

	my ($y, $m, $d) = ($day[5], $month{$day[1]}, $day[2]);
	
	my $f_day = $y .'-'. sprintf("%02d", $m) .'-'. sprintf("%02d", $d);
	
	$text =~ s/\n/\n    /g;

	add_log($user, $name, $text, "$home_dir/$f_day.txt");
}

set_since_id($id_file, $logged_id);

# 取得データ一覧表示
#for (@$data) { 
	#print encode_utf8($_->{'text'}), "\n";
	#for my $key (keys %$_) {
		#if ($key eq 'user') {
			#for my $k (keys %{$$_{$key}}) {
				#print $key .':'. $k .':'. encode_utf8(${$$_{$key}}{$k} or ''), "\n";
			#}
		#} else {
			#print encode_utf8($key) .':'. encode_utf8($$_{$key} or ''), "\n";
		#}
	#}
	#print "\n";
#}

sub add_log {
	my ($user, $name, $text, $filename) = @_;
	check_datafile($filename);
	open(OUT, ">>$filename");
	print OUT $user . ' / ' . $name . "\n";
	print OUT '    ' . $text . "\n";
	close(OUT);
}

sub v_length {
	my $_ = shift;
	my $ret = 0;
	while (/(?:(\p{InFullwidth}+)|(\p{InHalfwidth}+))/g) {
		$ret += ($1 ? length($1) * 2 : length($2));
	}
	return $ret;
}

sub get_since_id {
	my $log_file = shift;
	my $since_id = 0;
	open(IN, $log_file);
	my @in = <IN>;
	if ($in[0]) {
		chomp $in[0];
		$since_id = $in[0];
	}
	close(IN);
	return $since_id;
}

sub check_datafile {
	my $log_file = shift;
	if (!-e $log_file) {
		open(OUT, "> $log_file");
		close(OUT);
	}
}

sub set_since_id {
	my $log_file = shift;
	my $max_id = shift;
	open(OUT, ">$log_file");
	print OUT $max_id, "\n";
	close(OUT);
}

__END__

=head1 TTLL

Twitter TimeLine Logger

