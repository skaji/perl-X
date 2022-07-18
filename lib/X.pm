package X;
use v5.36;
use experimental qw(builtin defer for_list try);

use Data::Dumper ();
use HTTP::Tiny;
use IO::Socket::SSL;
use JSON::XS ();
use Time::HiRes ();

use Exporter 'import';
our @EXPORT = qw($JSON $HTTP dumper printd printj warnd warnj mono_clock);

our $JSON = JSON::XS->new->utf8->canonical;
our $HTTP = HTTP::Tiny->new;

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

package Monotonic::Clock {
    sub new ($class) {
        my $t = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
        bless \$t, $class;
    }
    sub elapsed ($self) {
        Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC()) - $$self;
    }
    sub sub ($self, $other) {
        $$self - $$other;
    }
}

sub mono_clock :prototype() {
    Monotonic::Clock->new;
}

1;
