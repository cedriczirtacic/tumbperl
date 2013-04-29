package Tumblr::OAuth;

use strict;
use warnings;
use Net::OAuth;

#use base qw( Tumblr::API );

use Exporter qw(import);
our @EXPORT;

@EXPORT	= qw(&request_token &request_access_token);

sub request_token($$\$)
{
	my($consumer_key,$consumer_secret,$ua)=@_;
	return undef unless(defined($consumer_key) && defined($consumer_secret));
	my(%oauth_tokens);

	my $_oauth_request=Net::OAuth->request('consumer')->new(
		consumer_key => $consumer_key,
		consumer_secret => $consumer_secret,
		request_url => "http://www.tumblr.com/oauth/request_token",
		request_method => 'POST',
		signature_method => 'HMAC-SHA1',
		timestamp => time,
		nonce => int(rand( 2**32 )),
		);
	$_oauth_request->sign;
	my $request_token_url=$_oauth_request->to_url;
	my $request_token_res=$$ua->post($request_token_url);
	
	if($request_token_res->is_success){
		my $resource_tokens=Net::OAuth->response('request token')->from_post_body($request_token_res->decoded_content);
		$oauth_tokens{token}=$resource_tokens->{token} if exists $resource_tokens->{token};
		$oauth_tokens{token_secret}=$resource_tokens->{token_secret} if exists $resource_tokens->{token_secret};
	}else{
		return undef;
	}

	return %oauth_tokens;
}

sub request_access_token($$\%\%\$)
{
	my $consumer_key=shift;
	my $consumer_secret=shift;
	my $oauth_tokens=shift;
	my $access_tokens=shift;
	my $ua=shift;
	my %oauth_tokens;
	return undef unless(defined($consumer_key) && defined($consumer_secret));
	
	my $_oauth_request;
	$_oauth_request=Net::OAuth->request('access token')->new(
		consumer_key => $consumer_key,
		consumer_secret => $consumer_secret,
		token => $$oauth_tokens{token},
		token_secret => $$oauth_tokens{token_secret},
		request_url => "http://www.tumblr.com/oauth/access_token",
		request_method => 'POST',
		signature_method => 'HMAC-SHA1',
		timestamp => time,
		nonce => int(rand( 2**32 )),
		verifier => $$access_tokens{oauth_verifier},
		extra_params => $access_tokens,
		);
	$_oauth_request->sign;

	my $access_token_res=$$ua->post($_oauth_request->to_url);
	if($access_token_res->is_success){
		my $access_response=Net::OAuth->response('access token')->from_post_body($access_token_res->decoded_content);
		$oauth_tokens{token}=$access_response->{token} if exists $access_response->{token};
		$oauth_tokens{token_secret}=$access_response->{token_secret} if exists $access_response->{token_secret};
	}else{
		return undef;
	}

	return %oauth_tokens;
}

1;
