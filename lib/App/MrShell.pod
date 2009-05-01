
=head1 NAME

App::MrShell - do everything the mrsh commandline tool can do and more

=head1 SYNOPSIS

my $mrsh = App::MrShell
    -> new
    -> set_hosts('host1', 'host2', 'host3')
    -> queue_command('uptime')
    -> queue_command('mii-tool', 'eth0')
    -> queue_command('dmesg | head')
    -> run_queue;

=head1 DESCRIPTION

=head1 FAQ

=head1 REPORTING BUGS

You can report bugs either via rt.cpan.org or via the issue tracking system on
github.  I'm likely to notice either fairly quickly.

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

=head1 COPYRIGHT

Copyright 2009 Paul Miller -- released under the GPL

=head1 SEE ALSO

perl(1), L<POE>, L<POE::Wheel::Run>, L<Term::ANSIColor>
