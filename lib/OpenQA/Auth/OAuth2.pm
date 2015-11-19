# Copyright (C) 2015 SUSE Linux GmbH
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.

package OpenQA::Auth::OAuth2;
use OpenQA::Schema::Result::Users;

use Config::IniFiles;
use Data::Dumper;
use Mojo::UserAgent;

require Exporter;

our (@ISA, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw/auth_config auth_login auth_response auth_logout/;

my $ua = Mojo::UserAgent->new;
my $cfgpath=$ENV{OPENQA_CONFIG} || '/etc/openqa';
my $cfg = Config::IniFiles->new(-file => $cfgpath.'/openqa.ini') || undef;
my %config = (
    'base_url' => $cfg->val('global', 'base_url'),
    'provider' => $cfg->val('oauth2', 'provider'),
    'client_id' =>$cfg->val('oauth2', 'client_id'),
    'client_key' =>$cfg->val('oauth2', 'client_key'),
);

sub auth_config {
    my ($config) = @_;
    # no config needed
    #
    return;
}

sub auth_logout {
    my ($self) = @_;

    my $logout_url = $config{'provider'}.'/oauth2/logout?callback='.$config{'base_url'};

    return ( redirect => $logout_url );
}


sub auth_login {
    my ($self) = @_;

    $config{'redirect_uri'} = $config{'base_url'}.'/login/redirect_back';
    my $req_url = $config{'provider'}."/oauth2/authorize?client_id=".$config{'client_id'}."&response_type=code&redirect_uri=".$config{'redirect_uri'};

    return ( redirect => $req_url );
}


sub auth_response {
    my ($self) = @_;

    $code = $self->param('code');
	my $resp = $ua->post($config{'provider'}."/oauth2/token" => {
        'Content-Type' => "application/x-www-form-urlencoded",
    } => form => {
			client_id => $config{'client_id'},
			client_secret => $config{'client_key'},
			grant_type => "authorization_code",
			code => $code,
			redirect_uri => $config{'redirect_uri'},
    });

    my $token = $resp->res->json->{'access_token'};
    my $user_info = get_user_info($self, $token);

    my $username = $user_info->{'username'};
    my $email = $user_info->{'email'};
    my $nickname = $user_info->{'username'};
    my $fullname = $user_info->{'username'};

    my $user = OpenQA::Schema::Result::Users->create_user($username, $self->db, email => $email, nickname => $nickname, fullname => $fullname);

    $self->session->{user} = $username;
    return ( error => 0 );
}

sub get_user_info{
    my ($self, $token) = @_;

    # tmp
    #$resp = $ua->get($config{'provider'}."/v1/user" => { 'Access-Token' => $token });
	$resp = $ua->get('https://api.deepin.org'."/v1/user" => { 'Access-Token' => $token });

    return $resp->res->json;
}

1;
