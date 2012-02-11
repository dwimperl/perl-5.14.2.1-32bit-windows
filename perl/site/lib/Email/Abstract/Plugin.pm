use strict;

package Email::Abstract::Plugin;

$Email::Abstract::Plugin::VERSION = '3.004';

=head1 NAME

Email::Abstract::Plugin - a base class for Email::Abstract plugins

=head1 METHODS

=head2 is_available

This method returns true if the plugin should be considered available for
registration.  Plugins that return false from this method will not be
registered when Email::Abstract is loaded.

=cut

sub is_available { 1 }

1;
