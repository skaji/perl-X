package attributes::EXPORT;
use v5.40;
use experimental qw(builtin class defer);

use meta;
no warnings 'meta::experimental';

sub import ($class) {
    my $caller = meta::get_package(scalar caller);

    my %export;
    my sub modify_attributes ($class, $ref, @attr) {
        my @attr2 = grep { $_ ne 'EXPORT' } @attr;
        if (@attr == @attr2) {
            return @attr;
        }
        $export{refaddr $ref} = true;
        @attr2;
    }
    my sub import ($class) {
        my %symbol;
        for my ($name, $symbol) ($caller->list_symbols) {
            my $ref = $symbol->reference;
            if ($export{refaddr $ref}) {
                $symbol{$name} = $ref;
            }
        }
        builtin::export_lexically %symbol if %symbol;
    }

    $caller->add_symbol('&MODIFY_CODE_ATTRIBUTES', \&modify_attributes);
    $caller->add_symbol('&MODIFY_SCALAR_ATTRIBUTES', \&modify_attributes);
    $caller->add_symbol('&import', \&import);
}
