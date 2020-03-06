package App::ProveMods;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::ProveDists ();
use Hash::Subset qw(hash_subset);

our %SPEC;

$SPEC{prove_mods} = {
    v => 1.1,
    summary => "Prove Perl modules' distributions",
    description => <<'_',

To use this utility, first create `~/.config/prove-mods.conf`:

    dists_dirs = ~/repos
    dists_dirs = ~/repos-other

The above tells *prove-mods* where to look for Perl distributions. Then:

    % prove-mods '^Regexp::Pattern.*'

This will search local CPAN mirror for all modules that match that regex
pattern, then search the distributions in the distribution directories (or
download them from local CPAN mirror), `cd` to each and run `prove` in it.

You can run with `--dry-run` (`-n`) option first to not actually run `prove` but
just see what distributions will get tested. An example output:

    % prove-mods '^Regexp::Pattern' -n
    ...

The above example shows that I have the distribution directories locally on my
`~/repos`, except for one 'Regexp::Pattern::License'.

If we reinvoke the above command without the `-n`, *prove-rdeps* will actually
run `prove` on each directory and provide a summary at the end. Example output:

    % prove-mods '^Regexp::Pattern'
    ...

The above example shows that one distribution failed testing. You can scroll up
for the detailed `prove` output to see the details of failure failed, fix
things, and re-run.

How distribution directory is searched: see <pm:App::ProveDists> documentation.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

*prove-rdeps* will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

_
    args => {
        %App::ProveDists::args_common,
        modules => {
            summary => 'Module names to prove',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'perl::modname*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub prove_mods {
    require App::lcpan::Call;

    my %args = @_;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ['mods', '-l', '-r', '--latest', '--or', @{ $args{modules} }],
    );

    return [412, "Can't lcpan mods: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;

    my @included_recs;
  REC:
    for my $rec (@{ $res->[2] }) {
        log_info "Found module: %s (dist=%s)", $rec->{module}, $rec->{dist};
        next if grep { $rec->{dist} eq $_->{dist} } @included_recs;
        push @included_recs, {dist=>$rec->{dist}};
    }

    App::ProveDists::prove_dists(
        hash_subset(\%args, \%App::ProveDists::args_common),
        _res => [200, "OK", \@included_recs],
    );
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See the included script L<prove-mods>.


=head1 SEE ALSO

L<prove>

L<App::lcpan>
