package Tumblr::API;

use strict;
use warnings;

use Data::Dumper;
use LWP::UserAgent;
use Carp;
use JSON;

use Tumblr::OAuth;

use Exporter qw( import );
our(@ISA, $VERSION);

@ISA		= qw( Exporter );
$VERSION	= '0.1';
our $api_url='http://api.tumblr.com/v2/';

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

sub new {
	my($class, %pkg)=@_;

	my $base_hostname=delete $pkg{base_hostname};
	my $consumer_key=delete $pkg{consumer_key};
	my $consumer_secret=delete $pkg{consumer_secret};
	my $oauth_callback=delete $pkg{oauth_callback};
	my $token_secret=delete $pkg{token_secret};
	my $token=delete $pkg{token};
	
	croak "Tumblr::API::consumer_key was not defined!" unless defined $consumer_key;
	croak "Tumblr::API::consumer_secret was not defined!" unless defined $consumer_secret;
	my $self=bless {
		'api_url'	=> $api_url,
		'consumer_key'	=> $consumer_key,
		'consumer_secret'	=> $consumer_secret,
		'token_secret'	=> $token_secret,
		'token'		=> $token,
		'base_hostname'	=> undef,
		'oauth_callback' => $oauth_callback,
				
		_useragent	=> LWP::UserAgent->new(),
		_json		=> JSON->new(),

		lastresponse	=> {},
	},$class;
	
	if(!defined($self->{base_hostname})){
		if(defined($base_hostname)){
			$self->{base_hostname}=$base_hostname;
		}
	}

	$self->{_useragent}->max_redirect(0);
	$self->{_useragent}->timeout(30);

	return $self;
}

##
# @desc		Get post from blog with ID
# @param int	$id	post id
# @param string	$blog	blog
# @return json
sub get_post($;$)
{
	my($self,$id,$blog)=@_;
	return $self->get_posts((defined $blog?$blog:undef),{id => $id});
}

##
# @desc		Get posts from blog
# @param string	$blog	blog
# @param ref	$params parameters for request
# @return json
sub get_posts(;$%)
{
	my($self,$blog,$params)=@_;
	my %data=(
		'api_key' => $self->{consumer_key},
	);
	my $posts_url="posts";

	if(exists $params->{type} && $params->{'type'} =~ /(text|quote|link|answer|video|audio|photo|chat)/){
		$posts_url.="/$params->{type}";
	}
	$data{'tag'}=$params->{'tag'} if exists($params->{'tag'});
	$data{'id'}=$params->{'id'} if(exists($params->{'id'}) && $params->{'id'} =~ /([0-9]+)/);
	$data{'limit'}=$params->{'limit'} if exists($params->{'limit'});
	$data{'offset'}=$params->{'offset'} if exists($params->{'offset'});
	$data{'reblog_info'}=$params->{'reblog_info'} if(exists($params->{'reblog_info'}) && $params->{'reblog_info'} =~ /(true|false)/);
	$data{'notes_info'}=$params->{'notes_info'} if(exists($params->{'notes_info'}) && $params->{'notes_info'} =~ /(true|false)/);
	$data{'filter'}=$params->{'filter'} if(exists($params->{'filter'}) && $params->{'filter'} =~ /(raw|text)/);
	
	if(defined($blog)){
		return $self->_request('API','GET', "blog/$blog/$posts_url", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('API','GET', "blog/$self->{base_hostname}/$posts_url", %data);
}

##
# @desc		Get info from blog
# @param string	$blog	blog
# @return json
sub get_info(;$)
{
	my($self,$blog)=@_;
	my %data=(
		'api_key' => $self->{consumer_key},
	);
	if(defined($blog)){
		return $self->_request('API','GET', "blog/$blog/info", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('API','GET', "blog/$self->{base_hostname}/info", %data);
}

##
# @desc		Get posts queue from blog
# @param int	$offset	number to start at
# @param int	$limit	number of results
# @param string	$filter filter raw/text
# @param string	$blog	blog
# @return json
sub get_posts_queue(;$$$$)
{
	my($self,$offset,$limit,$filter,$blog)=@_;
	my %data;
	$data{'offset'}=$offset if defined($offset);
	$data{'limit'}=$limit if defined($limit);
	$data{'filter'}=$filter if(defined $filter && $filter =~ /(raw|text)/);

	if(defined($blog)){
		return $self->_request('OAUTH','GET', "blog/$blog/posts/queue", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','GET', "blog/$self->{base_hostname}/posts/queue", %data);
}

##
# @desc		Get the set of draft posts from blog
# @param string	$filter filter raw/text
# @param string	$blog	blog
# @return json
sub get_posts_draft(;$$)
{
	my($self,$filter,$blog)=@_;
	my %data;
	$data{'filter'}=$filter if(defined $filter && $filter =~ /(raw|text)/);

	if(defined($blog)){
		return $self->_request('OAUTH','GET', "blog/$blog/posts/draft", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','GET', "blog/$self->{base_hostname}/posts/draft", %data);
}

##
# @desc		Get the set of draft posts from blog
# @param string	$filter filter raw/text
# @param string	$blog	blog
# @return json
sub get_posts_submission(;$$$)
{
	my($self,$offset,$filter,$blog)=@_;
	my %data;
	$data{'offset'}=$offset if(defined $offset);
	$data{'filter'}=$filter if(defined $filter && $filter =~ /(raw|text)/);

	if(defined($blog)){
		return $self->_request('OAUTH','GET', "blog/$blog/posts/submission", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','GET', "blog/$self->{base_hostname}/posts/submission", %data);
}

##
# @desc		Get likes from blog
# @param int	$limit	number of results
# @param int	$offset	number to start at
# @param string	$blog	blog
# @return json
sub get_likes(;$$$)
{
	my($self,$limit,$offset,$blog)=@_;
	my %data=(
		'api_key' => $self->{consumer_key},
	);
	$data{'limit'}=$limit if($limit);
	$data{'offset'}=$offset if($offset);
	if(defined($blog)){
		return $self->_request('API','GET', "blog/$blog/likes", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('API','GET', "blog/$self->{base_hostname}/likes", %data);
}

##
# @desc		Get followers from blog
# @param int	$limit	number of results
# @param int	$offset	number to start at
# @param string	$blog	blog
# @return json
sub get_followers(;$$$)
{
	my($self,$limit,$offset,$blog)=@_;
	my %data=();
	$data{'limit'}=$limit if($limit);
	$data{'offset'}=$offset if($offset);
	if(defined($blog)){
		return $self->_request('OAUTH','GET', "blog/$blog/followers", %data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','GET', "blog/$self->{base_hostname}/followers", %data);
}

##
# @desc		Get avatar from blog
# @param int	$size	get avatar from sizes: 16, 24, 30, 40, 48, 64, 96, 128, 512
# @param string	$blog	blog
# @return json
sub get_avatar(;$$)
{
	my($self,$size,$blog)=@_;
	if(defined($size)){
		$size=int($size);
		#TODO: Make checks more specific
		if(($size < 16 || $size > 512) || (($size % 4)!=0)){
			croak "Wrong \$size for get_avatar() function";
		}
	}

	my $avatar=(defined($size)?"avatar/$size":"avatar");
	if(defined($blog)){
		return $self->_request('API','GET', "blog/$blog/$avatar");
	}
	$self->_check_base_hostname();
	return $self->_request('API','GET', "blog/$self->{base_hostname}/$avatar");
}

##
# @desc		Get list of posts with "tag"
# @param string	$tag	tag to use
# @param int	$before	search for posts before timestamp
# @param int	$limit	number of results
# @param string	$filter	return with format raw/text
# @result json 
sub get_tagged($;$$$)
{
	my($self,$tag,$before,$limit,$filter)=@_;
	croak "\$tag must be defined" unless defined($tag);
	my %data=(
		'api_key' => $self->{consumer_key},
		'tag' => $tag,
	);
	$data{'before'}=$before if defined($before);
	$data{'limit'}=$limit if defined($limit);
	$data{'filter'}=$filter if defined($filter) && $filter =~ /(raw|text)/;

	return $self->_request('API','GET', "tagged", %data);
}

########
## POST functions
########

##
# @desc		Make a post
# @param string	$type	type of post: text, photo, quote, link, chat, audio or video
# @param int	$post_data	specify data to post
# @param int	$post_options	check the API for the list of options
# @param string	$blog	blog
# @result json 
sub post($$;$$)
{
	my($self,$type,$post_data,$post_options,$blog)=@_;
	my(%data);
	if(!defined($type) || $type !~ m/([0-9]+|text|photo|quote|link|chat|audio|video)/){
		croak "\$type must be defined as an id, text, photo, quote, link, chat, audio or video";
	}
	
	# Checks for different post types:
	if($type eq "text"){
		croak "'body' must be defined" if !defined($post_data->{body});
	}elsif($type eq "photo"){
		if(
			(!defined($post_data->{source}) && !defined($post_data->{data})) || 
			(defined($post_data->{source}) && defined($post_data->{data})) 
		){
			croak "Either 'source' or 'data' must be defined" ;
		}
	}elsif($type eq "quote"){
		croak "'quote' must be defined" if !defined($post_data->{quote});
	}elsif($type eq "link"){
		croak "'url' must be defined" if !defined($post_data->{url});
	}elsif($type eq "chat"){
		croak "'conversation' must be defined" if !defined($post_data->{conversation});
	}elsif($type eq "audio"){
		if(
			(!defined($post_data->{external_url}) && !defined($post_data->{data})) || 
			(defined($post_data->{external_url}) && defined($post_data->{data})) 
		){
			croak "Either 'external_url' or 'data' must be defined" ;
		}
	}elsif($type eq "video"){
		if(
			(!defined($post_data->{embed}) && !defined($post_data->{data})) || 
			(defined($post_data->{embed}) && defined($post_data->{data})) 
		){
			croak "Either 'embed' or 'data' must be defined" ;
		}
	}

	%data=%{$post_data};
	if($type =~/^[0-9]+/){ #if post ID
		$data{id}=$type;
	}else{ #if post type
		$data{type}=$type;
	}
	if(defined $post_options){
		# Now do checks for different post options:
		if(exists $post_options->{format}){
			croak "'format' must be html or markdown" if($post_options->{format} !~ /(html|markdown)/);
		}
		if(exists $post_options->{state}){
			croak "'state' must be published, draft, queue or private" if($post_options->{state} !~ /(published|draft|queue|private)/);
		}
		while(my($p,$v) = each(%{$post_options})){
			$data{$p}=$v;
		}
	}
	
	my $post_url="post";
	$post_url.="/edit" if(defined($data{id}));
	if(defined($blog)){
		return $self->_request('OAUTH','POST', "blog/$blog/$post_url",%data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','POST', "blog/$self->{base_hostname}/$post_url",%data);
}

##
# @desc		Edit a post
# @param int	$id	post id
# @param int	$post_data	specify data to post
# @param int	$post_options	check the API for the list of options
# @param string	$blog	blog
# @result json 
sub post_edit($$;$$){
	my($self,$id,$post_data,$post_options,$blog)=@_;
	return $self->post($id,$post_data,$post_options,$blog);
}

##
# @desc		Delete a post from blog
# @param int	$id	post id
# @param string	$blog	blog
# @return json
sub post_delete($;$)
{
	my($self,$id,$blog)=@_;
	croak "\$id must be defined" unless(defined $id);
	my %data;
	$data{'id'}=$id;

	if(defined($blog)){
		return $self->_request('OAUTH','POST', "blog/$blog/post/delete",%data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','POST', "blog/$self->{base_hostname}/post/delete",%data);
}

##
# @desc 	Reblog a post
# @param int	$id	post id
# @param string	$reblog_key	reblog key taken from post information
# @param string	$comment	reblog with comment
# @param string	$post_options	check the API for the list of options
# @param string	$blog	blog
# @return json
sub post_reblog($$;$$$)
{
	my($self,$id,$reblog_key,$comment,$post_options,$blog)=@_;
	croak "\$id and \$reblog_key must be defined" unless(defined $id && defined $reblog_key);
	my %data;
	$data{'id'}=$id;
	$data{'reblog_key'}=$reblog_key;
	$data{'comment'}=$comment if defined($comment);

	if(defined $post_options){
		# Now do checks for different post options:
		if(exists $post_options->{format}){
			croak "'format' must be html or markdown" if($post_options->{format} !~ /(html|markdown)/);
		}
		if(exists $post_options->{state}){
			croak "'state' must be published, draft, queue or private" if($post_options->{state} !~ /(published|draft|queue|private)/);
		}
		while(my($p,$v) = each(%{$post_options})){
			$data{$p}=$v;
		}
	}

	if(defined($blog)){
		return $self->_request('OAUTH','POST', "blog/$blog/post/reblog",%data);
	}
	$self->_check_base_hostname();
	return $self->_request('OAUTH','POST', "blog/$self->{base_hostname}/post/reblog",%data);
}

#######
## USER functions
#######

##
# @desc		Get user info
# @return json
sub user_info()
{
	my($self)=shift;
	return $self->_request('OAUTH','GET','user/info');
}

##
# @desc		Get posts from user's dashboard
# @param int	$limit	number of results
# @param int	$offset	number to start at
# @param hash	check the API for the list of options
# @return json
sub user_dashboard(;$$%)
{
	my($self,$limit,$offset,$post_options)=@_;
	my %data=%{$post_options};
	$data{'limit'}=$limit if defined($limit);
	$data{'offset'}=$offset if defined($offset);
	
	return $self->_request('OAUTH','GET','user/dashboard',%data);
}

##
# @desc		Get user likes
# @param int	$limit	number of results
# @param int	$offset	number to start at
# @return json
sub user_likes(;$$)
{
	my($self,$limit,$offset)=@_;
	my %data;
	$data{'limit'}=$limit if defined($limit);
	$data{'offset'}=$offset if defined($offset);
	
	return $self->_request('OAUTH','GET','user/likes',%data);
}

##
# @desc		List of followed blogs
# @param int	$limit	number of results
# @param int	$offset	number to start at
# @return json
sub user_following(;$$)
{
	my($self,$limit,$offset)=@_;
	my %data;
	$data{'limit'}=$limit if defined($limit);
	$data{'offset'}=$offset if defined($offset);
	
	return $self->_request('OAUTH','GET','user/following',%data);
}

##
# @desc		Follow a blog
# @param string	$url	blog URL to follow
# @return json
sub user_follow($)
{
	my($self,$url)=@_;
	my %data;
	croak "\$url must be defined" if !defined($url);
	$data{'url'}=$url;
	
	return $self->_request('OAUTH','POST','user/follow',%data);
}

##
# @desc		Unfollow a blog
# @param string	$url	blog URL to follow
# @return json
sub user_unfollow($)
{
	my($self,$url)=@_;
	my %data;
	croak "\$url must be defined" if !defined($url);
	$data{'url'}=$url;
	
	return $self->_request('OAUTH','POST','user/unfollow',%data);
}

##
# @desc		Like a post
# @param int	$id	post ID
# @param string $reblog_key	reblog_key from post information
# @return json
sub user_like($$)
{
	my($self,$id,$reblog_key)=@_;
	my %data;
	croak "\$id and \$reblog_key must be defined" if( !defined($id) || !defined($reblog_key) );
	$data{'id'}=$id;
	$data{'reblog_key'}=$reblog_key;
	
	return $self->_request('OAUTH','POST','user/like',%data);
}

##
# @desc		Unlike a post
# @param int	$id	post ID
# @param string $reblog_key	reblog_key from post information
# @return json
sub user_unlike($$)
{
	my($self,$id,$reblog_key)=@_;
	my %data;
	croak "\$id and \$reblog_key must be defined" if( !defined($id) || !defined($reblog_key) );
	$data{'id'}=$id;
	$data{'reblog_key'}=$reblog_key;
	
	return $self->_request('OAUTH','POST','user/unlike',%data);
}


#######
## Some internal funcions
#######
sub set_blog(;$)
{
	my($self,$blog)=@_;

	if(!defined($blog)){
		carp "There isn't a blog to defined request.";
		return 0;
	}
	$self->{base_hostname}=$blog;
	return 1;
}

sub _check_base_hostname()
{
	my $self=shift;
	if(!defined($self->{base_hostname})){
		croak "Tumblr::API::base_hostname isn't defined. Can't make a request!";
	}
}


sub _request($$$$;$)
{
	my($self, $auth, $method, $url, %data)=@_;
	my($_response,$_fullurl);
	return 0 unless(defined($auth));
	
	$_fullurl=$api_url;
	$_fullurl .= "/" if($api_url !~ m/\/$/ && $url !~ m/^\//);
	$_fullurl .= $url;
	if($method =~ /get/i){
		if(scalar(keys(%data))){
			$_fullurl.="?";
			while(my($_k,$_v)=each(%data)){
				$_fullurl .= "&" if($_fullurl !~ /\?$/);
				$_fullurl .= "$_k=$_v";
			}
		}
		if($auth eq 'API'){ #Auth: API KEY
			$_response=$self->{_useragent}->get($_fullurl);
		}elsif($auth eq 'OAUTH'){ #Auth: OAuth
			my $req_oauth=$self->_oauth_request($_fullurl,$method);
			$_response=$self->{_useragent}->get($req_oauth->to_url);
		}

	}elsif($method =~ /post/i){
		if($auth eq 'API'){ #Auth: API KEY
			$_response=$self->{_useragent}->post($_fullurl, Content => \%data);
		}elsif($auth eq 'OAUTH'){ #Auth: OAuth
			my $req_oauth=$self->_oauth_request($_fullurl,$method,%data);
			$self->{_useragent}->default_header('Authorization' => $req_oauth->to_authorization_header('tumblr.com')); 
			$_response=$self->{_useragent}->post($req_oauth->to_url, Content => \%data);
		}
	}
	
	if(!$_response->is_success){
		carp sprintf("Return from request wasn't OK: %d %s",
			$_response->code, $_response->message);
		$self->{lastresponse}= {'info' => 'error',
			'code' => $_response->code,
			'message' => $_response->message};
		if(length($_response->decoded_content) > 0){
			$self->{_json}->decode($_response->decoded_content);
		}else{ undef };
	}
	return $self->{_json}->decode($_response->decoded_content);
}

##
# @desc	Performs a GET/POST request using OAuth
# @param string	$url	URL to use with OAuth
# @param string	$method HTTP method to use: GET/POST
# @return	Net::OAuth::ProtectedResourceRequest
sub _oauth_request($$;%)
{
	my($self,$url,$method,%extra)=@_;
	return undef unless defined($url);
	my(%tokens,%access_token_params,%access_tokens);
	my $_oauth;
	
	if(!defined($self->{token}) || !defined($self->{token_secret})){
		%tokens=request_token($self->{consumer_key},
			$self->{consumer_secret},
			$self->{_useragent});
		
		if(!%tokens || !exists $tokens{token} || !exists $tokens{token_secret}){
			croak "Error getting the tokens for authorization.";
		}
	
		print sprintf("Please go to this website to get authorize: http://www.tumblr.com/oauth/authorize?oauth_token=%s\n",$tokens{token});
		print "Then paste the final URL and press enter.\n";
		my $verify_url=<STDIN>;
		chomp($verify_url);
		
		if($verify_url =~ m/^https*:\/\/[^\?]+\?([^\#]+)/gi){
			my(@verify_params)=split '&',$1;
			foreach my $param(@verify_params){
				my($p,$v)=$param=~m/^([^\=]+)\=(.+)$/g;
				$access_token_params{$p}=$v;
			}
		}else{
			croak "Wrong or invalid URL!";
		}
		
		%access_tokens=request_access_token($self->{consumer_key},
			$self->{consumer_secret},
			%tokens,
			%access_token_params,
			$self->{_useragent});
		
		if(!%access_tokens || !exists $access_tokens{token} || !exists $access_tokens{token_secret}){
			croak "Error getting the access tokens for making the request.";
		}

		$self->{token}=delete $access_tokens{token};
		$self->{token_secret}=delete $access_tokens{token_secret};
	}
	
	$_oauth=Net::OAuth->request("protected resource")->new(
		consumer_key => $self->{consumer_key},
		consumer_secret => $self->{consumer_secret},
		token => $self->{token},
		token_secret => $self->{token_secret},
		request_url => $url,
		request_method => $method,
		signature_method => 'HMAC-SHA1',
		timestamp => time,
		nonce => int(rand( 2**32 )),
		extra_params => ((scalar keys %extra)>0 ? \%extra : {}),
	);
	$_oauth->sign;
	return $_oauth;
}

1;
