package attributes::EXPORT;
use v5.40;
use experimental qw(builtin class defer);

my %export;
my $modify_attributes = sub ($, $v, @attr) {
    my @attr2 = grep { $_ ne 'EXPORT' } @attr;
    if (@attr == @attr2) {
        return @attr;
    }
    $export{refaddr $v} = true;
    return @attr2;
};

sub import ($) {
    my $caller = caller;
    no strict 'refs';
    *{ $caller . "::MODIFY_CODE_ATTRIBUTES" } = $modify_attributes;
    *{ $caller . "::MODIFY_SCALAR_ATTRIBUTES" } = $modify_attributes;
}

sub get_symbols ($, $package) {
    my %symbol;
    for my ($name, $v) (do { no strict 'refs'; %{ $package . "::" } }) {
        next if ref(\$v) ne 'GLOB';
        if (my $code = *{$v}{CODE}) {
            if ($export{refaddr $code}) {
                $symbol{ $name } = $code;
            }
        }
        if (my $scalar = *{$v}{SCALAR}) {
            if ($export{refaddr $scalar}) {
                $symbol{ '$' . $name } = $scalar;
            }
        }
    }
    \%symbol;
}
