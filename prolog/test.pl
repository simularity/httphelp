:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).

:- multifile http:location/3.

%       http:location(pldoc, Location, Options) is det.
%
%       Rebase PlDoc to <prefix>/help/source/

http:location(pldoc, root('help/source'), [priority(10)]).

:- use_module('help/load').

go :- http_server(http_dispatch, [port(5050)]).

