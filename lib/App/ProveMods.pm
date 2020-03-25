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
    prove-mods: Found module: Regexp::Pattern (dist=Regexp-Pattern)
    prove-mods: Found module: Regexp::Pattern::CPAN (dist=Regexp-Pattern-CPAN)
    prove-mods: Found module: Regexp::Pattern::Example (dist=Regexp-Pattern)
    prove-mods: Found module: Regexp::Pattern::Git (dist=Regexp-Pattern-Git)
    prove-mods: Found module: Regexp::Pattern::JSON (dist=Regexp-Pattern-JSON)
    prove-mods: Found module: Regexp::Pattern::License (dist=Regexp-Pattern-License)
    prove-mods: Found module: Regexp::Pattern::License::Parts (dist=Regexp-Pattern-License)
    prove-mods: Found module: Regexp::Pattern::Net (dist=Regexp-Pattern-Net)
    prove-mods: Found module: Regexp::Pattern::OS (dist=Regexp-Pattern-OS)
    prove-mods: Found module: Regexp::Pattern::Path (dist=Regexp-Pattern-Path)
    prove-mods: Found module: Regexp::Pattern::RegexpCommon (dist=Regexp-Pattern-RegexpCommon)
    prove-mods: Found module: Regexp::Pattern::Test::re_engine (dist=Regexp-Pattern-Test-re_engine)
    prove-mods: Found module: Regexp::Pattern::Twitter (dist=Regexp-Pattern-Twitter)
    prove-mods: Found module: Regexp::Pattern::YouTube (dist=Regexp-Pattern-YouTube)
    prove-mods: Found dist: Regexp-Pattern
    prove-mods: Found dist: Regexp-Pattern-CPAN
    prove-mods: Found dist: Regexp-Pattern-Git
    prove-mods: Found dist: Regexp-Pattern-JSON
    prove-mods: Found dist: Regexp-Pattern-License
    prove-mods: Found dist: Regexp-Pattern-Net
    prove-mods: Found dist: Regexp-Pattern-OS
    prove-mods: Found dist: Regexp-Pattern-Path
    prove-mods: Found dist: Regexp-Pattern-RegexpCommon
    prove-mods: Found dist: Regexp-Pattern-Test-re_engine
    prove-mods: Found dist: Regexp-Pattern-Twitter
    prove-mods: Found dist: Regexp-Pattern-YouTube
    prove-mods: [DRY] [1/12] Running prove for distribution Regexp-Pattern (directory /home/u1/repos/perl-Regexp-Pattern) ...
    prove-mods: [DRY] [2/12] Running prove for distribution Regexp-Pattern-CPAN (directory /home/u1/repos/perl-Regexp-Pattern-CPAN) ...
    prove-mods: [DRY] [3/12] Running prove for distribution Regexp-Pattern-Git (directory /home/u1/repos/perl-Regexp-Pattern-Git) ...
    prove-mods: [DRY] [4/12] Running prove for distribution Regexp-Pattern-JSON (directory /home/u1/repos/perl-Regexp-Pattern-JSON) ...
    prove-mods: [DRY] [5/12] Running prove for distribution Regexp-Pattern-License (directory /tmp/hEa7jnla5M/Regexp-Pattern-License-v3.2.0) ...
    prove-mods: [DRY] [6/12] Running prove for distribution Regexp-Pattern-Net (directory /home/u1/repos/perl-Regexp-Pattern-Net) ...
    prove-mods: [DRY] [7/12] Running prove for distribution Regexp-Pattern-OS (directory /home/u1/repos/perl-Regexp-Pattern-OS) ...
    prove-mods: [DRY] [8/12] Running prove for distribution Regexp-Pattern-Path (directory /home/u1/repos/perl-Regexp-Pattern-Path) ...
    prove-mods: [DRY] [9/12] Running prove for distribution Regexp-Pattern-RegexpCommon (directory /home/u1/repos/perl-Regexp-Pattern-RegexpCommon) ...
    prove-mods: [DRY] [10/12] Running prove for distribution Regexp-Pattern-Test-re_engine (directory /home/u1/repos/perl-Regexp-Pattern-Test-re_engine) ...
    prove-mods: [DRY] [11/12] Running prove for distribution Regexp-Pattern-Twitter (directory /home/u1/repos/perl-Regexp-Pattern-Twitter) ...
    prove-mods: [DRY] [12/12] Running prove for distribution Regexp-Pattern-YouTube (directory /home/u1/repos/perl-Regexp-Pattern-YouTube) ...

The above example shows that I have the distribution directories locally on my
`~/repos`, except for one 'Regexp::Pattern::License'.

If we reinvoke the above command without the `-n`, *prove-mods* will actually
run `prove` on each directory and provide a summary at the end. Example output:

    % prove-mods '^Regexp::Pattern'
    ...
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
    | dir                                           | label                               | reason                            | status |
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+
    | /tmp/2GOBZuxird/Regexp-Pattern-License-v3.2.0 | distribution Regexp-Pattern-License | Test failed (Failed 1/2 subtests) | 500    |
    +-----------------------------------------------+-------------------------------------+-----------------------------------+--------+

The above example shows that one distribution failed testing. You can scroll up
for the detailed `prove` output to see the details of failure failed, fix
things, and re-run.

How distribution directory is searched: see <pm:App::ProveDists> documentation.

When a dependent distribution cannot be found or downloaded/extracted, this
counts as a 412 error (Precondition Failed).

When a distribution's test fails, this counts as a 500 error (Error). Otherwise,
the status is 200 (OK).

*prove-mods* will return status 200 (OK) with the status of each dist. It will
exit 0 if all distros are successful, otherwise it will exit 1.

_
    args => {
        %App::ProveDists::args_common,
        modules => {
            summary => 'Module names to prove',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'re*'],
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
        -dry_run => $args{-dry_run},
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
