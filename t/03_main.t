use strict;
use Test::More tests => 15;
use Redis::Connector;


my $KEY        = 'REDIS-CONNECTOR-TEST:counter';
my $INIT_VALUE = 343;


my $redis = Redis::Connector->new();
isa_ok($redis->handle, 'Redis', 'handle() stores Redis instance');

eval {
    # reconnection
    my $handle = $redis->handle;
    cmp_ok($handle, 'eq', $redis->handle, 'Same handle');
    undef $redis->{handle};
    isa_ok($redis->handle, 'Redis', 'Reconnected');
    
    $redis->handle->set($KEY, $INIT_VALUE);
    cmp_ok($redis->handle->get($KEY), '==', $INIT_VALUE, 'counter initialized');
    
    # aborted transaction
    eval {
        $redis->transaction(sub {
            my $r = shift;
            isa_ok($r, 'Redis', 'Transaction got Redis as first argument');
            $r->incr($KEY);
            cmp_ok($r->get($KEY), 'eq', 'QUEUED', 'Transaction is active');
            die 'module-test';
        });
    };
    if ( my $error = $@ ) {
        pass('Exception in transaction rethrown');
        if ( $error =~ m{\A module-test [ ] at [ ] }xms ) {
            cmp_ok($redis->handle->get($KEY), '==', $INIT_VALUE, 'Transaction aborted');
        }
        else {
            die $error; # something wrong
        }
    }
    else {
        fail('Exception in transaction was not rethrown');
    }
    
    # successful transactions
    my @values = $redis->transaction(sub {
        my $r = shift;
        $r->incr($KEY);
        cmp_ok($r->get($KEY), 'eq', 'QUEUED', 'Counter incremented');
        $r->incr($KEY);
    });
    cmp_ok(@values,                   '==', 3,               'Transaction return some values');
    cmp_ok($values[0],                '==', $INIT_VALUE + 1, 'Transaction first increment');
    cmp_ok($values[1],                '==', $INIT_VALUE + 1, 'Get value in transaction');
    cmp_ok($values[2],                '==', $INIT_VALUE + 2, 'Transaction second increment');
    cmp_ok($redis->handle->get($KEY), '==', $INIT_VALUE + 2, 'Transaction success');
    
    # clean out
    ok(eval {$redis->handle->del($KEY); 1 }) or diag($@);
};
if ( my $error = $@ ) {
    eval { $redis->handle->del($KEY); 1 } or diag($@);
    die $error;
}
