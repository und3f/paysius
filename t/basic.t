#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Business::Paysius;

my $paysius = new_ok 'Business::Paysius', [key => 'KEY', secret => 'SECRET'];
subtest 'hmac digest' => sub {
    is $paysius->digest({q => 'test'}),
      '3de1e948874479b4e64d3a741bc9e797e24f9efd41b2c634375e405deba5749f0cf9aa8e98331576442263ecb4706de9c8ed2988c710c8aba086c2231decf528';
};

subtest 'generate request' => sub {
    my $request =
      $paysius->generate_request(qw(api getnewaddress), (qty => 2));

    is $request->method, 'POST';
    is $request->uri,    'https://paysius.com:53135/api/getnewaddress';

    my %content = map(+(split /=/), split(/\&/, $request->content));
    is_deeply \%content, {
        'hmac' =>
          '469f31d2fc75913eb6587a8085316261ed85c9f7ed41e97665fc824f58dd3f12a4966d718cb2dc080e7fd271f9c2aec30874d532d4f64fef93c31000a40b4dd6',
        'qty' => '2',
        'key' => 'KEY'
      };
};

subtest 'process response' => sub {
    subtest 'correct response' => sub {
        my $r = $paysius->process_response(<<RESPONSE);
{"hmac":"fdccae274ca35edfdc4e747f6730fd7125931451688169160465ed559f2304d4d0434a8511940033e9476e250e46c8a63dc94a436cb900ca3befb1676f32adeb",
"response":{"key":"value"}}
RESPONSE

        is_deeply $r, {key => "value"};
    };

    subtest 'error response' => sub {
        eval {
            $paysius->process_response(
                '{"ERRORCODE": 25, "ERRORMESSAGE": "Invalid hash"}');
        };
        like $@, qr(Paysius error 25: Invalid hash), 'exception generated';
    };

    subtest 'response with wrong hmac' => sub {
        eval {
            $paysius->process_response('{"hmac": "1234f", "response": {}}');
        };
        like $@, qr(Response is not authenticate: invalid hash);
    };
};

done_testing();
