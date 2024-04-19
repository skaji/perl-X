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

my %EXPORT; BEGIN {
    sub MODIFY_CODE_ATTRIBUTES ($, $code, @attr) {
        return @attr if $attr[0] ne 'EXPORT';
        $EXPORT{builtin::refaddr $code} = builtin::true;
        return;
    }
    sub MODIFY_SCALAR_ATTRIBUTES ($, $scalar, @attr) {
        return @attr if $attr[0] ne 'EXPORT';
        $EXPORT{builtin::refaddr $scalar} = builtin::true;
        return;
    }
}

our $HTTP :EXPORT = HTTP::Tiny->new(verify_SSL => 1);
our $JSON :EXPORT = Cpanel::JSON::XS->new->utf8->canonical;
our $JSON_PRETTY :EXPORT = Cpanel::JSON::XS->new->utf8->canonical->pretty->space_before(0)->indent_length(2);

sub encode_json :EXPORT ($argv) {
    $JSON->encode($argv);
}

sub encode_json_pretty :EXPORT ($argv) {
    $JSON_PRETTY->encode($argv);
}

sub decode_json :EXPORT ($argv) {
    $JSON->decode($argv);
}

sub load_json :EXPORT ($argv = \*STDIN) {
    my $fh;
    if (ref $argv) {
        $fh = $argv;
    } else {
        open $fh, "<", $argv or die "$!: $argv";
    }
    my $c = do { local $/; <$fh> };
    $JSON->decode($c);
}

sub dumper :EXPORT (@argv) {
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

sub printd :EXPORT (@argv) {
    print dumper @argv;
}

sub printj :EXPORT ($argv) {
    print encode_json($argv) . "\n";
}

sub printjp :EXPORT ($argv) {
    print encode_json_pretty($argv);
}

sub warnd :EXPORT (@argv) {
    warn dumper @argv;
}

sub warnj :EXPORT ($argv) {
    warn encode_json($argv) . "\n";
}

sub warnjp :EXPORT ($argv) {
    warn encode_json_pretty($argv);
}

sub query_form :EXPORT ($url) {
    +{ URI->new($url)->query_form };
}

sub steady_time :EXPORT :prototype() () {
    Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
}

# my $time = mktime year => 2017, month => 2, day => 1;
sub mktime :EXPORT (%argv) {
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
sub strptime :EXPORT ($string, $format) {
    if ($string =~ /%/) {
        require Carp;
        Carp::croak("the first argument of strptime('$string', '$format') must not be FORMAT");
    }
    state $tzoffset = Time::Piece->localtime->tzoffset->seconds;

    die "cannot parse %z/%Z correctly" if $format =~ /%[zZ]/;
    my $gmtime = Time::Piece->strptime($string, $format);
    $gmtime->epoch - $tzoffset;
}

sub time2str :EXPORT ($time) {
    POSIX::strftime("%F %T", localtime $time);
}

sub camel_case :EXPORT ($str) {
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

sub snake_case :EXPORT { goto \&String::CamelSnakeKebab::lower_snake_case }
sub str2time :EXPORT { goto \&HTTP::Date::str2time }
sub strftime :EXPORT { goto \&POSIX::strftime }
sub ONE_DAY :EXPORT { goto \&Time::Seconds::ONE_DAY }

sub import ($class) {
    my $caller = caller;

    my $export = sub ($name, $v) {
        $name = '$' . $name if ref($v) ne 'CODE';
        builtin::export_lexically $name, $v;
    };
    # my $export = sub ($name, $ref) {
    #     no strict 'refs';
    #     *{ $caller . "::$name" } = $ref;
    # };

    for my ($name, $v) (do { no strict 'refs'; %{ $class . "::" }}) {
        next if ref(\$v) ne 'GLOB';
        if (my $code = *{$v}{CODE}) {
            if ($EXPORT{builtin::refaddr $code}) {
                $export->($name, $code);
            }
        }
        if (my $scalar = *{$v}{SCALAR}) {
            if ($EXPORT{builtin::refaddr $scalar}) {
                $export->($name, $scalar);
            }
        }
    }
    for my ($name, $v) (%{ builtin:: }) {
        next if ref(\$v) ne 'GLOB';
        next if $name =~ /^(BEGIN|VERSION)$/n;
        if (my $code = *{$v}{CODE}) {
            $export->($name, $code);
        }
    }

    experimental->import(qw(builtin defer for_list try class));
}
