/*  Part of ClioPatria

    Author:        Michiel Hildebrand
    WWW:           http://www.swi-prolog.org
    Copyright (c)  2010-2012 University of Amsterdam
		             CWI, Asterdam
		             VU University Amsterdam
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/


:- module(cp_help, []).
:- use_module(library(doc_http)).		% Load pldoc

:- use_module(library(http/http_hook)).		% Get hook signatures
:- include(library(pldoc/hooks)).
:- use_module(library(http/http_server_files)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/html_write)).

:- ensure_loaded(http_help).		% Help on HTTP server

:- multifile user:file_search_path/2.
:- writeln('I loaded').

user:file_search_path(library, lib).

add_path(Name) :-
	writeln('got in'),
	prolog_load_context(directory, Dir),
	write('Dir is '),writeln(Dir),
	atomic_list_concat([Dir, '/../web/', Name, '/'], APath),
	write('APath is '),writeln(APath),
	absolute_file_name(APath, Path),
	write('Path is '),writeln(Path),
	asserta(user:file_search_path(Name, Path)).

:- add_path(js).
:- add_path(css).
:- add_path(icons).

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
		    hr(' '),
                    div(id(content), Body)
                  ])).

