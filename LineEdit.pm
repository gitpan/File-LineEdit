package File::LineEdit;
use strict;
use FileHandle;
use Carp 'croak';
use vars qw[$VERSION];
# use Debug::ShowStuff ':all';
use overload '@{}' => sub { $_[0]->{lines} };


# version
$VERSION = '1.12';


# documentation is at the end of the file




#------------------------------------------------------------------------------
# new
# 
sub new {
	my ($class, $path, %opts) = @_;
	my $self = bless({}, $class);
	my ($read, @lines, $chomp);

	if (exists $opts{'autochomp'})
		{$chomp = $opts{'autochomp'}}
	else
		{$chomp = 1}
	
	if (exists $opts{'autosave'})
		{$self->{'autosave'} = $opts{'autosave'}}
	else
		{$self->{'autosave'} = 1}
	
	# if lines should be automatically chomped
	# after they are read
	$self->{'autochomp'} = $chomp;
	
	# the path of the original file
	$self->{'orgpath'} = $path;
	
	# the path to save to, defaults to the path
	# of the original file
	if (exists $opts{'savepath'})
		{$self->{'savepath'} = $opts{'savepath'}}
	else
		{$self->{'savepath'} = $path}
	
	# open a file handle for reading the original file
	$read = FileHandle->new($path)
		or croak "unable to read file $path: $!";
	
	# slurp the entire original file in
	while (my $line = <$read>) {
		chomp $line if $chomp;
		push @lines, $line;
	}
	
	# hold on to the lines in the original file
	$self->{'lines'} = \@lines;
	
	# we're ready, return the object
	return $self;
}
# 
# new
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# save
# 
sub save {
	my ($self) = @_;
	my ($out);
	
	$out = FileHandle->new("> $self->{'savepath'}")
		or croak "unable to open file $self->{'savepath'} for write: $!";
	
	foreach my $line (@{$self->{'lines'}}){
		print $out $line;
		
		if ($self->{'autochomp'})
			{print $out "\n"}
	}
	
	return 1;
}
# 
# save
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
# 
DESTROY {
	my ($self) = @_;
	
	if ($self->{'autosave'})
		{$self->save}
}
# 
# DESTROY
#------------------------------------------------------------------------------


###############################################################################
# File::LineEdit::Tie
# 
package File::LineEdit::Tie;
use strict;

sub TIEARRAY {
	my ($class, $path) = @_;
	my $self = bless({}, $class);
	
	$self->{'le'} = File::LineEdit->new($path);
	$self->{'lines'} = $self->{'le'}->{'lines'};
	
	return $self;
}

sub FETCHSIZE { scalar @{$_[0]->{'lines'}} }
sub STORESIZE { $#{$_[0]->{'lines'}} = $_[1]-1 }
sub STORE     { $_[0]->{'lines'}->[$_[1]] = $_[2] }
sub FETCH     { $_[0]->{'lines'}->[$_[1]] }
sub CLEAR     { @{$_[0]->{'lines'}} = () }
sub POP       { pop(@{$_[0]->{'lines'}}) }
sub PUSH      { my $o = shift; push(@{$o->{'lines'}},@_) }
sub SHIFT     { shift(@{$_[0]->{'lines'}}) }
sub UNSHIFT   { my $o = shift; unshift(@{$o->{'lines'}},@_) }
sub EXISTS    { exists $_[0]->{'lines'}->[$_[1]] }
sub DELETE    { delete $_[0]->{'lines'}->[$_[1]] }

sub SPLICE {
	my $ob  = shift;
	my $sz  = $ob->FETCHSIZE;
	my $off = @_ ? shift : 0;
	$off   += $sz if $off < 0;
	my $len = @_ ? shift : $sz-$off;
	return splice(@{$ob->{'lines'}},$off,$len,@_);
}

# 
# File::LineEdit::Tie
###############################################################################



# return true
1;

__END__

=head1 NAME

File::LineEdit - Small utility for editing each line of a file


=head1 SYNOPSIS
 
 # object interface
 my $le = File::LineEdit->new('myfile.txt');
 foreach my $line (@$le)
	{$line =~ s|foo|bar|}
 
 # tied array interface
 my (@le);
 tie @le, 'File::LineEdit::Tie', 'myfile.txt';
 foreach my $line (@le)
	{$line =~ s|foo|bar|}
 untie @le;

=head1 INSTALLATION

File::LineEdit can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

You can also just copy LineEdit.pm into the File/ directory of one of your
library trees.

=head1 DESCRIPTION

File::LineEdit is just a small utility to simplify modiyfying a file
line-by-line.  It performs the boring tasks of slurping in the file, chomping
each line (if you want it to), and then, after changes are made, writing the
data back to the file.

The basic usage is quite simple: instantiate a File::LineEdit object, loop
through the object as if it were an array, modifying each line however you
want. When the object falls out of scope, it automatically writes the modified
lines back to the file.  Here's a simple example (actually, the same example
used in the synopsis above, this time with a little more documentation):

 # instantiate a File::LineEdit object, passing in 
 # the path to the file as the only required argument.
 my $le = File::LineEdit->new('myfile.txt');
 
 # loop through the lines in the file
 foreach my $line (@$le) {
     
     # change the line in some way
     $line =~ s|foo|bar|;
 
 }
 
 # The data is saved back to the file
 # automatically when the object falls
 # out of scope.  No need for an
 # explicit save.

There are a few variations on this theme.

=head2 Explicit save

By default, LineEdit objects save their line data back

If you just somehow don't trust the concept of saving on object destruction,
you can tell your LineEdit object to explicitly save:

 $le->save;

If you don't want the object to automatically save on destruction,
add the C<autosave> argument to the instantiation params:

 my $le = File::LineEdit->new('myfile.txt', autosave=>0);

=head2 Saving to a different file

You might prefer to slurp data in from one file, then save to another.
To do so, just add the C<savepath> parameter to the C<new()> call.
For example, the following command slurps from C<source.txt> and
saves to C<target.txt>:

 my $le = File::LineEdit->new('source.txt', savepath=>'target.txt');

You can also set the save path after object creation by setting
the C<savepath> property:

=head2 Automatic line chomping

By default, LineEdit automatically chomps the end of each line when it slurps
in the data from the file.  If you prefer to keep your lines unchomped then
add an C<autochomp> argument to the instantiation params:

 my $le = File::LineEdit->new('myfile.txt', autochomp=>0);


=head1 TIED ARRAY INTERFACE

You can also use File::LineEdit as a tied array.  Just tie your
array to File::LineEdit::Tie, passing the file path as the 
only argument:

 # tied array interface
 my (@le);
 tie @le, 'File::LineEdit::Tie', 'myfile.txt';
 foreach my $line (@le)
	{$line =~ s|foo|bar|}
 untie @le;

=head1 SIMILAR MODULES

There are a couple modules on CPAN that provide similar functionality. 
File::Searcher provides the ability to do regular expression based search and
replaces on groups of files.  File::Data provides several ways to slurp in, 
modify, and write files.  File::Data also uses regular expressions for
searching and replacing.  Be sure to look at both of those modules if 
you are interested in simplified modification of files.

File::LineEdit differs from File::Searcher and File::Data in that
File::LineEdit focuses on line-based edits.  The object of
File::LineEdit is to provide a simplified manner for looking at and 
modifying files one line at a time.

=head1 TERMS AND CONDITIONS

Copyright (c) 2003 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan F<miko@idocs.com>

Useful contribution by Dan Brook.

=head1 VERSION

=over

=item Version 1.00    June 27, 2003

Initial release

=item Version 1.11    June 30, 2003

Added overloading so that you can reference the LineEdit object itself 
as if it were a reference to an array.  That was Dan Brook's idea.
Thanks Dan!

Then I took Dan's idea a step further and added the ability to tie
File::LineEdit to an array using File::LineEdit::Tie.

=item Version 1.12    July 3, 2003

Added ability to set the object to save to a different file than
the file the data was slurped from.  Also tidied up documentation
a little.

=back

=cut
