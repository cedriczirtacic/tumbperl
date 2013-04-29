tumbperl.
=============
tumbperl. (or Tumblr::API) is an unofficial Perl client for the Tumblr API.


Installation
-------------

### Manual

To install the module just copy the Tumblr/ folder to your common perl libraries directory. For example:

```console
$ perl -V:archlib
archlib='/usr/lib/perl5';
```

Then, as a superuser o someone similar, copy the dir:

```
$ cp -r Tumblr/ /usr/lib/perl5
```

Test if you can successfully load the module:

```
$ perl -e 'use Tumblr::API;'
```

### Using Module::Build

You might want to run the installation as a superuser.

```console
$ perl Build.PL
$ ./Build install
```

Examples
--------

Get information from user:

```perl
#!/usr/bin/perl
 
use strict;
use warnings;
 
use Tumblr::API;
 
my $tumblr = Tumblr::API->new(
       consumer_key    => 'your_consumer_key',
       consumer_secret => 'your_consumer_secret',
       base_hostname   => 'your_blog_hostname',
       );
 
my $blog_info= $tumblr->get_info();
if($blog_info->{meta}->{msg} eq "OK"){
        printf "This blog has %d posts\n", $blog_info->{response}->{blog}->{posts};
        exit 0;
}else{
        print STDERR "Error getting blog info.\n";
        exit 1;
}
```

Dependencies
------------

List of dependencies needed by this module:
* [JSON][2]
* [Net::OAuth][3]


Bugs
----

For bugs or related [mail me][1].

Author
------

[Cedric Zirtacic (cicatriz)][1]

[1]: mailto:cicatriz.r00t@gmail.com
[2]: http://search.cpan.org/~makamaka/JSON-2.53/lib/JSON.pm
[3]: http://search.cpan.org/dist/Net-OAuth/lib/Net/OAuth.pm
