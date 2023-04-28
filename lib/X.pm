package X 0.001;
use v5.36;
use experimental qw(builtin defer for_list try);

use Cpanel::JSON::XS ();
use Data::Dumper ();
use HTTP::Date ();
use HTTP::Tiny;
use IO::Socket::SSL ();
use POSIX ();
use String::CamelSnakeKebab ();
use Time::HiRes ();
use Time::Local ();
use Time::Piece ();

use Exporter qw(import);

our @EXPORT = qw(
    $HTTP
    encode_json encode_json_pretty decode_json load_json
    dumper
    printd printj printjp warnd warnj warnjp
    camel_case snake_case const_case

    steady_time strftime strptime str2time time2str mktime
);

our $HTTP = HTTP::Tiny->new(verify_SSL => 1);

my $JSON = Cpanel::JSON::XS->new->utf8->canonical;
my $JSON_PRETTY = Cpanel::JSON::XS->new->utf8->canonical->pretty->space_before(0)->indent_length(2);

sub encode_json ($argv) {
    $JSON->encode($argv);
}

sub encode_json_pretty ($argv) {
    $JSON_PRETTY->encode($argv);
}

sub decode_json ($argv) {
    $JSON->decode($argv);
}

sub load_json ($argv) {
    my $fh;
    if (ref $argv) {
        $fh = $argv;
    } else {
        open $fh, "<", $argv or die "$!: $argv";
    }
    my $c = do { local $/; <$fh> };
    $JSON->decode($c);
}

sub dumper (@argv) {
    Data::Dumper
        ->new([])
        ->Trailingcomma(1)
        ->Terse(1)
        ->Indent(1)
        ->Useqq(1)
        ->Deparse(1)
        ->Quotekeys(0)
        ->Sortkeys(1)
        ->Values(\@argv)
        ->Dump;
}

sub printd (@argv) {
    print dumper @argv;
}

sub printj ($argv) {
    print encode_json($argv) . "\n";
}

sub printjp ($argv) {
    print encode_json_pretty($argv);
}

sub warnd (@argv) {
    warn dumper @argv;
}

sub warnj ($argv) {
    warn encode_json($argv) . "\n";
}

sub warnjp ($argv) {
    warn encode_json_pretty($argv);
}

sub HTTP::Tiny::post_json ($self, $url, $data) {
    my $content = encode_json $data;
    my $res = $self->post($url, {
        headers => {
            'content-type' => 'application/json',
            'content-length' => length $content,
        },
        content => $content,
    });
    if (!$res->{success}) {
        die "$res->{status} $res->{reason}, $url\n";
    }
    decode_json $res->{content};
}

sub steady_time :prototype() {
    Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
}

# my $time = mktime year => 2017, month => 2, day => 1;
sub mktime (%argv) {
    Time::Local::timelocal_posix(
        ($argv{second} || 0),
        ($argv{minute} || 0),
        ($argv{hour}   || 0),
        ($argv{day}    || die),
        ($argv{month}  || die) - 1,
        ($argv{year}   || die) - 1900,
    );
}

# my $t = strptime("2018-01-01", "%Y-%m-%d");
sub strptime ($string, $format) {
    state $tzoffset = Time::Piece->localtime->tzoffset->seconds;

    die "cannot parse %z/%Z correctly" if $format =~ /%[zZ]/;
    my $gmtime = Time::Piece->strptime($string, $format);
    $gmtime->epoch - $tzoffset;
}

sub time2str ($time) {
    POSIX::strftime("%F %T", localtime $time);
}

sub camel_case ($str) {
    if ($str =~ /^[A-Z]/) {
        return String::CamelSnakeKebab::upper_camel_case $str;
    }
    return String::CamelSnakeKebab::lower_camel_case $str;
}

{
    no warnings 'once';
    *snake_case = \&String::CamelSnakeKebab::lower_snake_case;
    *const_case = \&String::CamelSnakeKebab::constant_case;
    *str2time = \&HTTP::Date::str2time;
    *strftime = \&POSIX::strftime;
}

1;
