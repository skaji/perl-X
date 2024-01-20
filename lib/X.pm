package X 0.001;
use v5.38;
use experimental qw(builtin defer for_list try class);

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
use Time::Seconds ();
use URI ();
use builtin ();

our @EXPORT = qw(
    encode_json encode_json_pretty decode_json load_json
    dumper
    printd printj printjp warnd warnj warnjp
    query_form
    camel_case snake_case const_case

    steady_time strftime strptime str2time time2str mktime
    ONE_DAY

    true false is_bool
    weaken unweaken is_weak
    blessed refaddr reftype
    created_as_string created_as_number
    ceil floor
    indexed
    trim
    is_tainted
    export_lexically
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

sub query_form ($url) {
    +{ URI->new($url)->query_form };
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
    if ($string =~ /%/) {
        require Carp;
        Carp::croak("the first argument of strptime('$string', '$format') must not be FORMAT");
    }
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

sub HTTP::Tiny::post_json ($self, $url, $argv) {
    $argv->{content} = encode_json $argv->{content};
    $argv->{headers} ||= {};
    $argv->{headers}{'Content-Type'} = 'application/json';
    $argv->{headers}{'Content-Length'} = length $argv->{content};
    $self->post($url, $argv);
}

{
    no warnings 'once';
    *snake_case = \&String::CamelSnakeKebab::lower_snake_case;
    *const_case = \&String::CamelSnakeKebab::constant_case;
    *str2time = \&HTTP::Date::str2time;
    *strftime = \&POSIX::strftime;
    *ONE_DAY = \&Time::Seconds::ONE_DAY;

    *true = \&builtin::true;
    *false = \&builtin::false;
    *is_bool = \&builtin::is_bool;
    *weaken = \&builtin::weaken;
    *unweaken = \&builtin::unweaken;
    *is_weak = \&builtin::is_weak;
    *blessed = \&builtin::blessed;
    *refaddr = \&builtin::refaddr;
    *reftype = \&builtin::reftype;
    *created_as_string = \&builtin::created_as_string;
    *created_as_number = \&builtin::created_as_number;
    *ceil = \&builtin::ceil;
    *floor = \&builtin::floor;
    *indexed = \&builtin::indexed;
    *trim = \&builtin::trim;
    *is_tainted = \&builtin::is_tainted;
    *export_lexically = \&builtin::export_lexically;
}

sub import ($class, @name) {
    experimental->import(qw(builtin defer for_list try class));
    builtin::export_lexically '$HTTP', \$HTTP;
    for my $export (@EXPORT) {
        no strict 'refs';
        builtin::export_lexically $export, \&{$export};
    }
}
