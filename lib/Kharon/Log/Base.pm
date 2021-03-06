#
# Provides a base logging class which forms the basis for all
# logging...

package Kharon::Log::Base;

use Carp;

use warnings;
use strict;

sub new {
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	my $self = {
		sess_id	=> 0,
		msg_num => 0,
		debug   => 0,
	};

	bless($self, $class);
}

sub set_sess_id {
	my ($self, $sess_id) = @_;

	# XXXrcd: error checking?  Is everything valid?
	$self->{sess_id} = $sess_id;
}

sub log {
	my ($self, $level, @args) = @_;

	return if $level eq 'debug' && $self->{debug} == 0;
	$self->output_log($level, $self->construct_log(@args));
}

sub cmd_log {
	my ($self, $level, $code, $cmd, @args) = @_;

	my $msg = "cmdresult|$code|$cmd|";

	if (defined($args[0]) && ref($args[0]) eq '') {
		$msg .= $args[0];
	}
	$self->log($level, $msg);
}

sub construct_log {
	my ($self, @args) = @_;

	# Our logmsg format:
	# time|gmtime|pid|session id|msg num|cont?|msg...
	#
	# Where
	#	session id is a unique session id chosen by the app
	#	msg num is a strictly increasing integer, starting at 0
	#	cont is a continuation indicator, "C" indicates this
	#		line is a continuation of the last, " " otherwise.

	my $preamble = time . "|" . gmtime() . "|$$|" . $self->{sess_id};
	my $msg = join(" ", @args);
	my $offset = 0;
	my @ret;

	for (my $offset=0; $offset < length($msg); $offset += 500) {
		push(@ret, "$preamble|" . $self->{msg_num}++ . "|" .
		    (($offset != 0) ? "C" : " ") . "|" .
		    substr($msg, $offset, 500));
	}
	@ret;
}

sub output_log {

	confess("Abstract implementation invoked.");
}

1;
