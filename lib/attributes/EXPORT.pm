package attributes::EXPORT;
use v5.40;
use experimental qw(builtin class defer);

use meta;
no warnings 'meta::experimental';

my %export;

sub import ($) {
    my sub modify_attributes ($, $v, @attr) {
        my @attr2 = grep { $_ ne 'EXPORT' } @attr;
        if (@attr == @attr2) {
            return @attr;
        }
        $export{refaddr $v} = true;
        return @attr2;
    }

    my $caller = caller;
    my $meta = meta::get_package($caller);
    $meta->add_symbol('&MODIFY_CODE_ATTRIBUTES' => \&modify_attributes);
    $meta->add_symbol('&MODIFY_SCALAR_ATTRIBUTES' => \&modify_attributes);
}

sub get_symbols ($, $package) {
    my $meta = meta::get_package($package);
    my %symbol;
    for my ($name, $symbol) ($meta->list_symbols) {
        my $ref = $symbol->reference;
        if ($export{refaddr $ref}) {
            $symbol{$name} = $ref;
        }
    }
    \%symbol;
}
