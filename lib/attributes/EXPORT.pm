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
        my $kaller = meta::get_package(scalar caller);
        for my ($name, $symbol) ($caller->list_symbols) {
            my $ref = $symbol->reference;
            if ($export{refaddr $ref}) {
                if ($name =~ s/^\$//) {
                    no strict 'refs';
                    *{ $kaller->name . "::$name" } = $ref;
                } else {
                    $kaller->add_symbol($name, $ref);
                }
            }
        }
    }

    $caller->add_symbol('&MODIFY_CODE_ATTRIBUTES', \&modify_attributes);
    $caller->add_symbol('&MODIFY_SCALAR_ATTRIBUTES', \&modify_attributes);
    $caller->add_symbol('&import', \&import);
}
