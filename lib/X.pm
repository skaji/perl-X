package X;
use v5.36;
use experimental qw(builtin defer for_list try);

use Cpanel::JSON::XS ();
use Data::Dumper ();
use HTTP::Tiny;
use IO::Socket::SSL;
use Time::HiRes ();
use String::CamelSnakeKebab qw(constant_case);

use Exporter 'import';

our @EXPORT = qw(
    $HTTP
    encode_json encode_json_pretty decode_json load_json
    dumper
    printd printj printjp warnd warnj warnjp
    mono_clock
    camel_case snake_case constant_case
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

sub mono_clock :prototype() {
    Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
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
}

1;
