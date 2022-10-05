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
    $JSON $JSON_INDENT $HTTP
    dumper printd printj warnd warnj
    mono_clock
    camel_case snake_case constant_case
);

our $JSON = Cpanel::JSON::XS->new->utf8->canonical;
our $JSON_INDENT = Cpanel::JSON::XS->new->utf8->canonical->pretty->space_before(0)->indent_length(2);
our $HTTP = HTTP::Tiny->new(verify_SSL => 1);

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
    print $JSON->encode($argv) . "\n";
}

sub warnd (@argv) {
    warn dumper @argv;
}

sub warnj ($argv) {
    warn $JSON->encode($argv) . "\n";
}

package JSON::XS {
    sub load ($self, $argv) {
        my $fh;
        if (ref $argv) {
            $fh = $argv;
        } else {
            open $fh, "<", $argv or die "$argv: $!";
        }
        my $c = do { local $/; <$fh> };
        $self->decode($c);
    }
}

package HTTP::Tiny {
    sub post_json ($self, $url, $data) {
        my $content = $JSON->encode($data);
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
        $JSON->decode($res->{content});
    }
    sub graphql ($self, $url, $query, $variables = undef) {
        $self->post_json($url, {
            query => $query,
            ($variables ? (variables => $variables) : ()),
        });
    }
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
