package SMS::Send::US::Verizon;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

use LWP::UserAgent;
use URI::Escape;
use base 'SMS::Send::Driver';

use constant TO_NUM_LEN  => 10;  # Enforce that "to" contains this many digits.
use constant MAX_MSG_LEN => 160; # Enforce that total message is not more than this number of characters.

sub new {
   return bless {}, shift;  
}

# "Characters typed in the From, Your Message, Reply To Address and Callback Number fields all 
# count toward the 160-character message length."

sub send_sms {
    my ($self, %args) = @_;
    my $url = 'https://text.vzw.com/customer_site/jsp/messaging_lo.jsp';
 
    my %params = (
        'trackResponses' => 'No',
        'Send.x'         => 'Yes',
        'translatorButton' => '',
        'showgroup'      => 'n',
        'DOMAIN_NAME'    => '@vtext.com',
        'min'            => $args{'to'}        || '', # "Send To"
        'text'           => $args{'text'}      || '', # "Your Message"
        'count'          => MAX_MSG_LEN,
        'subject'        => $args{'_subject'}  || '', # "From" (gets wrapped in " (" and ") " after _from
        'sender'         => $args{'_from'}     || '', # "Reply To Address" (should be email or phone number)
        'callback'       => $args{'_callback'} || '', # "Callback Number"
        'type'           => $args{'_priority'} || 0,  # Priority: 0 (Normal) or 1 (Urgent)
        # 'Reset'          => 1,
        'Send'           => 1,
    );

    # Message received is something like "Fr:_from (_subject) _text\nCB:_callback"
    # Hard line break appears at first space in all text.  (So, multi-word _from may wrap awkwardly)
    # If _subject is missing, parenthesis will not be inserted.

    # Only digits are allowed in 'to' and '_callback'
    $params{'min'} =~ s{\D}{}g; # remove non-digits
    $params{'callback'} =~ s{\D}{}g; # remove non-digits
    
    # 'to' must be exactly 10 digits long.
    Carp::croak("'to' must contain ".TO_NUM_LEN." digits") if length $params{'min'} != TO_NUM_LEN;
    
    my $msg_length = 
        length( $params{'sender'} ) + length( $params{'text'} ) + 
        length( $params{'subject'} ) + length( $params{'callback'} );
    $params{'count'} = MAX_MSG_LEN - $msg_length;
    
    if ($params{'count'}<0) {
        # If too long, verizon automatically truncates it and sends anyway.
        Carp::carp("'_from', 'text', '_callback' and '_subject' combined must not be more than "
            . MAX_MSG_LEN." characters.  " . $msg_length . " characters supplied.  Message will be truncated");
    }
    
    # Do the send
    my $content = join( '&', map { $_ . '=' . uri_escape( $params{ $_ } ) } keys %params );

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new( 'POST' => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( $content );

    my $res = $ua->request($req);

    my $status = "";
    if( $res->is_success ) {
        if ($res->content =~ m{name="STATUS_MSGID" value='([^\']+)'}) {
            $status=$1;
            if ($res->content =~ m{<td width="15%"><font class='smallText'>([^<]+)</font></td>}) {
                $status .= " - $1";
            }
            else {
                $status .= " - Status message unavailable";
            }
        }
        else {
            $@ = "MsgID*_******** - Tracking ID unavailable";
        }
    }
    else {
        $@ = "Failed: HTTP response code ".$res->code." ".$res->message;
    }
    return $status;  # return a false value upon error.  SMS::Send does not like undef upon failure.
}

1; 

__END__

=head1 NAME

SMS::Send::US::Verizon - SMS::Send driver for the text.vzw.com website

=head1 VERSION

This document describes SMS::Send::US::Verizon version 0.0.1

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('US::Verizon');

    $sender->send_sms(
        'to'        => '202-555-2368',      # ten digit, Verizon number
        'text'      => "You'll never believe me!",     #
        '_from'     => 'phalliwell@charmed-gmail.com', # 
        '_callback' => '415-555-0198',      # 
        '_subject'  => '',                  # If specified, will appear after _from in parenthesis.
        '_priority' => 1,                   # Use "1" for Urgent messages.  Default is 0 for Normal messages.
    ) or _handle_sms_error( $@ );  
  

=head1 DESCRIPTION

Sends an SMS::Send message to Verizon US customers when used as the L<SMS::Send> driver.  This uses the
Verizon web interface at L<https://text.vzw.com/customer_site/jsp/messaging_lo.jsp>.

Uses 'to' and 'text' as per L<SMS::Send> and additionally uses '_from', '_callback', '_subject', and '_priority'

Another way to send text messages to Verizon Wireless subscribers is by email.  Send an email
to C<xxxxxxxxxx@vtext.com> where C<xxxxxxxxxx> is the subscriber's 10-digit wireless number.


=head1 INTERFACE 

=head2 new

No authentication parameters necessary.

  SMS::Send->new('US::Verizon');

=head2 send_sms

If send_sms() returns true, then the return value is the Tracking ID or the message and the initial status of the send.

  print $sender->send_sms( to => "4155550198", text => "Hi!" );  # Returns something like "MsgID5_ABCDEFGH - Sending your message" upon success.

This return value may change in format and/or text in future versions.

If send_sms() returns false then C<$@> is set to the error message.


=head1 DIAGNOSTICS

=over

=item C<< 'to' must contain 10 digits >>

The value passed to 'to' does not have ten digits.

=item C<< '_from', 'text', '_callback' and '_subject' combined must not be more than 160 characters >>

The length of characters in '_from', 'text', '_callback' and '_subject' combined are too long.  Message will be
sent, but it will be truncated by Verizon.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
SMS::Send::US::Verizon requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<LWP::UserAgent>, L<URI::Escape>, L<SMS::Send::Driver>


=head1 INCOMPATIBILITIES

None known.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.  Heavily reliant upon Verizon Wireless' web interface.  A change there may break this.

Please report any bugs or feature requests to
C<bug-sms-send-us-verizon@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Karl Lohner C<< <karllohner+sms-send-us-verizon@gmail.com> >>


=head1 CREDITS

Based on SMS::Send::US::TMobile by Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Karl Lohner. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
