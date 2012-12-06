package Business::Paysius;

use strict;
use warnings;

require Carp;
use Digest::SHA;
use HTTP::Request::Common q(POST);
use JSON qw(encode_json decode_json);
use LWP::UserAgent;

sub new {
    my ($class, %args) = @_;

    foreach my $arg (qw(key secret)) {
        Carp::croak("$arg parameter missed") unless exists $args{$arg};
    }

    bless {
        gateway => 'https://paysius.com:53135',
        ua      => LWP::UserAgent->new(ssl_opts => {verify_hostname => 0}),
        %args
    }, $class;
}

sub digest {
    my ($self, $params) = @_;

    Digest::SHA::hmac_sha512_hex(encode_json($params), $self->{secret});
}

sub generate_request {
    my ($self, $method_type, $method, %params) = @_;

    my $url = join '/', $self->{gateway}, $method_type, $method;

    $params{key} = $self->{key};
    POST $url, [%params, hmac => $self->digest(\%params)];
}

sub process_response {
    my ($self, $response_content) = @_;

    my $response = decode_json $response_content;

    Carp::croak(
        "Paysius error $response->{ERRORCODE}: $response->{ERRORMESSAGE}")
      unless exists $response->{response};

    # This check fails bacouse of difference in hash keys order
    die "Response is not authenticate: invalid hash"
      unless ($self->digest($response->{response}) eq $response->{hmac});

    $response->{response};
}

sub request {
    my $self = shift;

    my $http_response = $self->{ua}->request($self->generate_request(@_));
    Carp::croak($http_response->status_line)
      unless $http_response->is_success;

    $self->process_response($http_response->decoded_content);
}

# API Methods
sub getNewAddress {
    my ($self, $qty) = @_;
    $qty = 1 unless defined $qty;
    $self->request(qw(api getnewaddress), qty => "$qty");
}

sub getAddressInfo {
    my ($self, $address) = @_;
    $self->request(qw(api getaddressinfo), address => $address);
}

sub sendBitcoin {
    my ($self, $address, $amount) = @_;
    $self->request(
        qw(api sendbitcoin),
        address => $address,
        amount  => "$amount"
    );
}

sub getBalance { shift->request(qw(api getbalance)) }

# SCI Methods
sub setDetails {
    my ($self, $total, $curcode, $return_url, $cancel_url) = @_;
    $self->request(
        qw(sci setdetails),
        total        => "$total",
        curcode      => $curcode,
        'return-url' => $return_url || '',
        'cancel-url' => $cancel_url || ''
    );
}

sub getDetails {
    my ($self, $uuid) = @_;

    $self->request(qw(sci getdetails), uuid => $uuid);
}

sub updateOrder {
    my ($self, $uuid, $total, $curcode, $return_url, $cancel_url) = @_;
    $self->request(
        qw(sci updateorder),
        uuid         => $uuid,
        total        => "$total",
        curcode      => $curcode,
        'return-url' => $return_url || '',
        'cancel-url' => $cancel_url || ''
    );
}

sub getOrderAddress {
    my ($self, $uuid) = @_;

    $self->request(qw(sci getorderaddress), uuid => $uuid);
}

1;
