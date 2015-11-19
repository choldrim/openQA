package OpenQA::Controller::DeepinSession;
use Mojo::Base 'Mojolicious::Controller';

use Carp;
use Net::OpenID::Consumer;
use URI::Escape;
use LWP::UserAgent;
use OpenQA::Schema::Result::Users;

sub redirect_back {
    my ($self) = @_;

    my $auth_method = $self->app->config->{'auth'}->{'method'};
    my $auth_module = "OpenQA::Auth::$auth_method";
    $auth_module->import('auth_response');

    my %res = auth_response($self);

    if (%res) {
        if ($res{'redirect'}) {
            return $self->redirect_to($res{'redirect'});
        }
        elsif ($res{'error'}) {
            return $self->render(text => $res{'error'}, status => 403);
        }
        return $self->redirect_to('index');
    }
    return $self->render(text => 'Forbidden', status => 403);
}


sub destroy {
    my ($self) = @_;

    my $auth_method = $self->app->config->{'auth'}->{'method'};
    my $auth_module = "OpenQA::Auth::$auth_method";
    eval {$auth_module->import('auth_logout');};

    my %res = auth_logout($self);

    delete $self->session->{user};

    if ($res{'redirect'}) {
        return $self->redirect_to($res{'redirect'});
    }
    else{
        return $self->redirect_to('index');
    }
}

1;
