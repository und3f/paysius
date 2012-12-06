use inc::Module::Install;

name 'WWW::Paysius';
all_from 'lib/WWW/Paysius';

requires 'Digest::SHA';
requires 'HTTP::Request::Common';
requires 'JSON';
requires 'LWP::UserAgent';

WriteAll;
