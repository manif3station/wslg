use strict;
use warnings;

use Test::More;

ok( -f 'README.md', 'README exists' );
ok( -d 'docs', 'docs directory exists' );
ok( -f 'docs/overview.md', 'overview doc exists' );
ok( -f 'docs/usage.md', 'usage doc exists' );
ok( -d 'docs/changes', 'changes docs directory exists' );
ok( -f 'docs/changes/2026-05-18-initial-release.md', 'initial change record exists' );
ok( -f 'docs/changes/2026-05-18-desktop-launcher-release.md', 'desktop launcher change record exists' );
ok( -f 'docs/changes/2026-05-18-service-enable-order-fix.md', 'service-enable order fix record exists' );
ok( -f 'docs/changes/2026-05-18-human-readable-summary.md', 'human-readable summary change record exists' );
ok( -f 'tickets/SOW.md', 'SOW ticket exists' );
ok( -f 'tickets/EPIC-205.md', 'epic ticket exists' );
ok( -f 'tickets/DD-240.md', 'ticket record exists' );
ok( -f 'tickets/TESTING.md', 'testing record exists' );
ok( -f '.env', '.env exists' );
ok( -f 'Changes', 'Changes file exists' );
ok( -f 'cpanfile', 'cpanfile exists' );
ok( -x 'cli/setup', 'setup CLI wrapper is executable' );
ok( -x 'cli/desktop', 'desktop CLI wrapper is executable' );

my $readme = do {
    open my $fh, '<', 'README.md' or die "Unable to read README.md: $!";
    local $/;
    <$fh>;
};
like( $readme, qr/dashboard wslg\.setup/, 'README documents dashboard wslg.setup' );
like( $readme, qr/dashboard wslg\.desktop/, 'README documents dashboard wslg.desktop' );
like( $readme, qr/dashboard skills install wslg/, 'README uses the short install form' );
like( $readme, qr/Ubuntu `20\.04`, `22\.04`, and `24\.04`/, 'README documents supported Ubuntu versions' );
like( $readme, qr/--dry-run/, 'README documents the dry-run flow' );

my $env = do {
    open my $fh, '<', '.env' or die "Unable to read .env: $!";
    local $/;
    <$fh>;
};
like( $env, qr/^VERSION=0\.04$/m, '.env stores the skill version' );

done_testing;
