:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).

user:file_search_path(library, lib).
user:file_search_path(skin, skin).
user:file_search_path(components, components).
user:file_search_path(web, './web').
user:file_search_path(js, './web/js').
user:file_search_path(css, './web/css').
user:file_search_path(icons, './web/icons').

:- use_module('help/load').

:- multifile http:location/3.
user:location(css, '/css' , []).
user:location(js, '/js', []).
user:location(js, '/icons', []).

:- http_handler(css(.), serve_files_in_directory(css),
		[priority(-100), prefix]).
:- http_handler(icons(.), serve_files_in_directory(icons),
		[priority(-100), prefix]).
:- http_handler(js(.), serve_files_in_directory(js),
		[priority(-100), prefix]).

:- multifile
        user:body//2.

user:body(http_help, Body) -->
        html(body([ div(id(top), h1('HTTP Endpoints')),
                    div(id(content), Body)
                  ])).

go :- http_server(http_dispatch, [port(5050)]).

