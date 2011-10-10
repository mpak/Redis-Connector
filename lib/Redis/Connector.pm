package Redis::Connector;
use strict;
use warnings;
use Redis;

our $VERSION = '0.03';



sub new {
    my $class = shift;
    my %args
        = ( ref $_[0] eq 'HASH' ) ? %{$_[0]}
        :                           @_
        ;
    my $password = delete $args{password};
    my $dbindex  = delete $args{dbindex};
    my $self     = {
        handle   => undef,
        conf     => \%args,
        password => $password,
        dbindex  => $dbindex,
        pid      => 0,
    };
    return bless $self, ref $class || $class;
}



sub handle {
    my $self  = shift;
    return $self->{handle}
        if $self->_is_connected();
    
    # try reconnect
    return $self->_connect();
}



# execute commands in transaction
# automatically rollback on failure and rethrow error
sub transaction {
    my ( $self, $code ) = @_;
    if ( ref $code ne 'CODE' ) {
        require Carp;
        Carp::croak('CODE reference expected');
    }
    my $redis = $self->handle;
    $redis->multi();
    eval { $code->($redis) };
    if ( my $err = $@ ) {
        eval { $redis->discard() }; # mask possible error
        die $err;                   # rethrow exception
    }
    return $redis->exec();
}



sub _connect {
    my $self = shift;
    $self->{handle} = Redis->new(%{ $self->{conf} });
    $self->{pid   } = $$;
    if ( $self->{password} ) {
        $self->{handle}->auth($self->{password});
    }
    if ( $self->{dbindex} ) {
        $self->{handle}->select($self->{dbindex});
    }
    return $self->{handle};
}



sub _is_connected {
    my $self = shift;
    return $self->{pid   } == $$
        && $self->{handle} 
        && $self->{handle}->ping
        ;
}


1;

__END__

=head1 NAME

Redis::Connector - wrapper around Redis with autoreconnect support


=head1 SYNOPSIS

    use Redis::Connector;
    my $conn = Redis::Connector->new();
    # or my $conn = Redis::Connector->new({});
    
    # access to Redis object
    $conn->handle->incr('foo');
    
    # transaction procession
    eval {
        my @values = $conn->transaction(sub {
            my $r = shift;
            $r->incr('foo');
        });
        # transaction complete
        # @values contains result of exec()
    };
    if ( $@ ) {
        # transaction failed, discard() already executed
    }


=head1 DESCRIPTION

Reconnect to Redis DB after fork() or in case of ping() failures.
Provide handy transaction procession.
Does not delegate to methods of Redis.


=head1 METHODS

=head2 C<< new(arg => value) >>

=head2 C<< new({ arg => value }) >>

Create object. Arguments are the same as for C<< Redis->new() >>.
Additional arguments:

=over

=item password

If present will automatically call auth() after connect.

=item dbindex

Database index. Will be automatically selected after connect.

=back

=head2 C<handle()>

Return Redis instance. First it checks that PID was not changed from last time.
Then calls ping() and in case of failure tries create new Redis object.

=head2 C<transaction(CODE)>

If error occured during transaction every following multi() will throw exception.
So you should explicitly run discard().

    try {
        $r->multi();
        ...
        $r->exec();
    }
    catch {
        # Oops!
        $r->discard();
    };

This method do it for you. It executes CODE in transaction
with Redis instance in first argument (so it will not reconnect on failure).
On failure it will call discard() and rethrow exception.
On success return result of exec().


=head1 SEE ALSO

L<Redis>


=head1 AUTHOR

Andrey Fedorov E<lt>secrethost@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Andrey Fedorov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
