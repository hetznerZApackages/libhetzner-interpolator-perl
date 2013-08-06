# Copyright 2004, Hetzner Africa.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND ITS EMPLOYEES
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: Interpolator.pm,v 1.1 2004/01/30 09:34:57 ianf Exp $

package HETZNER::Interpolator;

$HETZNER::Interpolator::VERSION = '1.0';

use Class::MethodMaker
	new_with_init 	=> 'new',
	new_hash_init	=> '_init_args',
	get_set		=> [ qw( filename delim_re depth inc_re contents) ];

sub HETZNER::Interpolator::init {
	my ($self, $args, $hash_ref) = @_;
	$self->_init_args(%{$args});

	$self->{delim_re} = defined($self->{delim_re}) ? 
	    $self->{delim_re} : q{\$([a-z_][a-z0-9_]*)};

	if ($self->{delim_re} !~ m/\(.*\)/) {
		die "delim_re does not contain '()'";
	}

	$self->{depth} = defined($self->{depth}) ? ++$self->{depth} : 0;

	$self->{inc_re} = defined($self->{inc_re}) ? 
	    $self->{inc_re} : q{^\s?#include '(.*)'$};

	if ($self->{inc_re} !~ m/\(.*\)/) {
		die "inc_re does not contain '()'";
	}
	
	if (defined($self->{filename}) && defined($hash_ref)) {
		$self->load_file($hash_ref);
	}

	return $self;
}

sub HETZNER::Interpolator::load_file {
	my ($self, $args) = @_;

	# Guard against recursive include files
	if ($self->{depth} >= 10) { 
		die "recursive include in file ".$self->{filename};
	} 
	
	if (!defined($self->{filename}) || $self->{filename} eq "") {
		die "HETZNER::Interpolator::load_file : filname not specified";
	}

	open(F,$self->{filename}) || 
	    die "Could not open " .$self->{filename}." : $!";
	my $local = join("",<F>);
	close(F);
	
	# Do the parsing
	my $repl_re = qr/$self->{delim_re}/;
	while ($local =~ m/$repl_re/gmc) {
		my $token = $1;
		
		if (!exists($$args{$token})) {
			die $self->{filename}." : $token does not exist";
		} elsif (!defined($$args{$token})) {
			die $self->{filename}." : $token is not defined";
		}

		my $replace = $$args{$token};
		$local =~ s/$repl_re/$replace/e;
	}

	# Resolve includes
	my $inc_re = $self->{inc_re};

	while ( $local =~ m/($inc_re)/gmc ) {
		my ($repl, $fname) = ($1,$2);
		my $p = new HETZNER::Interpolator({ filename => $fname,
				     depth => $self->{depth} }, $args);
		$p->load_file($args);
		my $new = $p->contents();
		$local =~ s/$repl/$new/m;
	}
	# Return parsed contents, for recursive case
	$self->contents($local);
}

sub HETZNER::Interpolator::Stringify { return $_[0]->{contents}; }

use overload
	'""' => \&Stringify;

1;
