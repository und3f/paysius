#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Business::Paysius;

plan skip_all => 'set PAYSIUS env variable to KEY:SECRET'
  unless $ENV{PAYSIUS};
my ($key, $secret) = split /:/, $ENV{PAYSIUS};

my $paysius = Business::Paysius->new(key => $key, secret => $secret);

subtest "API" => sub {
    my $balance = $paysius->getBalance;
    ok exists $balance->{btc};

    my $address = $paysius->getNewAddress(1);
    ok exists $address->{address0};

    my $info = $paysius->getAddressInfo($address->{address0});
    ok exists $info->{received};

  SKIP: {
        skip "we don't have funds", 1;
        my $transaction = $paysius->sendBitcoin($address->{address0}, 1);
        ok exists $transaction->{txid};
    }
};

subtest "SCI" => sub {
    my $uuid = $paysius->setDetails(10.0, 'USD');
    ok exists $uuid->{uuid};
    $uuid = $uuid->{uuid};

    my $order = $paysius->getDetails($uuid);
    use Data::Dumper;
    warn Dumper $order;
};

done_testing();
