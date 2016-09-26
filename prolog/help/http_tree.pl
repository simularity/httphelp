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


:- module(http_tree,
	  [ http_tree_view//1
	  ]).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/html_head)).
:- use_module(library(http/html_write)).
:- use_module(library(http/yui_resources)).
:- use_module(library(pairs)).

/** <module> Create YUI tree from HTTP locations

This module provides the  component   http_tree_view//1  and  associated
helpers.
*/

:- http_handler(root(help/expand_http_node), expand_http_node, []).

%%	http_tree_view(+Options)//
%
%	Show hierarchy of HTTP locations (paths).  The tree is a YUI
%	tree that can be expanded dynamically.

http_tree_view(Options) -->
	tree_view(expand_http_node, Options).


% the folders/tree.css file must be last.  Because requirements are made
% unique and sorted using toplogical sort, this  can only be achieved by
% declaring the other files as dependencies.

:- html_resource(yui_examples('treeview/assets/css/folders/tree.css'),
		 [ requires([ yui('treeview/treeview.js'),
			      yui('connection/connection.js'),
			      yui('treeview/assets/skins/sam/treeview.css')
			    ])
		 ]).


tree_view(Handler, Options) -->
	{ http_location_by_id(Handler, Path),
	  TreeViewID = treeDiv1
	},
	html([ \html_requires(yui_examples('treeview/assets/css/folders/tree.css')),
	       \html_requires(css('httpdoc.css')),
	       \html_requires(pldoc),
	       \html_requires(js('api_test.js')),

	       div(id(TreeViewID), []),
	       \tree_view_script(Path, TreeViewID, Options)
	     ]).

tree_view_script(Path, TreeViewID, Options) -->
	html(script(type('text/javascript'), \[
'var currentIconMode = 0;\n',		% ??
'function buildTree() {\n',
'   tree = new YAHOO.widget.TreeView("~w");\n'-[TreeViewID],
'   tree.setDynamicLoad(loadNodeData, currentIconMode);\n',
\tree_options(Options),
'   var root = tree.getRoot();\n',
'\n',
'   var tempNode = new YAHOO.widget.TextNode("/", root, true);\n',
'   tempNode.data = { path:"/" };\n',
'   tree.draw();\n',
'}\n',

'function loadNodeData(node, fnLoadComplete)  {\n',
'    var sUrl = "~w?node=" + encodeURIComponent(node.data.path);\n'-[Path],
'    var callback = {\n',
'        success: function(oResponse) {\n',
'	     var children = eval(oResponse.responseText);\n',
'	     for (var i=0, j=children.length; i<j; i++) {\n',
'		 var tempNode = new YAHOO.widget.TextNode(children[i], node, false);\n',
'            }\n',
'            oResponse.argument.fnLoadComplete();\n',
'        },\n',
'        failure: function(oResponse) {\n',
'            oResponse.argument.fnLoadComplete();\n',
'        },\n',
'        argument: {\n',
'            "node": node,\n',
'            "fnLoadComplete": fnLoadComplete\n',
'        },\n',
'        timeout: 7000\n',
'    };\n',
'    YAHOO.util.Connect.asyncRequest("GET", sUrl, callback);\n',
'}\n',

%'YAHOO.util.Event.onDOMReady(buildTree());\n'
'buildTree();\n'
					     ])).

tree_options([]) --> [].
tree_options([H|T]) --> tree_option(H), tree_options(T).

tree_option(labelClick(JS)) --> !,
	html([ 'tree.subscribe("labelClick", ~w);\n'-[JS] ]).
tree_option(_) -->
	[].

%%	expand_http_node(+Request)
%
%	HTTP handler that returns the children of an HTTP node.

expand_http_node(Request) :-
	http_parameters(Request,
			[ node(Parent, [ description('HTTP location to refine')])
			]),
	node_children(Parent, Children),
	reply_json(Children, []).

node_children(Parent, Children) :-
	ensure_ends_slash(Parent, Parent1),
	findall(Sub, sub_handler(Parent1, Sub), Subs),
	map_list_to_pairs(first_component(Parent), Subs, Keyed0),
	keysort(Keyed0, Keyed),
	group_pairs_by_key(Keyed, Groups),
	maplist(decorate, Groups, Children).

ensure_ends_slash(Path, Path) :-
	sub_atom(Path, _, _, 0, /), !.
ensure_ends_slash(Path, PathSlash) :-
	atom_concat(Path, /, PathSlash).

sub_handler(Parent, Sub) :-
	http_current_handler(Sub, _:_, _),
	sub_atom(Sub, 0, _, A, Parent),
	A > 0.

first_component(Parent, Path, ParentExt) :-
	atom_length(Parent, PL),
	sub_atom(Path, B, _, _, /),
	B > PL, !,
	sub_atom(Path, 0, B, _, ParentExt).
first_component(_, Path, Path).


decorate(Prefix-[Only],
	 json([label(Label), isLeaf(@(true)), path(Only)])) :-
	atom_concat(Prefix, Rest, Only),
	(   Rest == ''
	;   Rest == /
	), !,
	file_base_name(Prefix, Label0),
	leaf_label(Only, Label0, Label).
decorate(Prefix-_,
	 json([label(Label), isLeaf(@(false)), path(Prefix)])) :-
	file_base_name(Prefix, Label).

leaf_label(Only, Label0, Label) :-
	http_current_handler(Only, _:_, Options),
	(   memberchk(prefix(true), Options)
	->  atom_concat(Label0, '...', Label)
	;   Label = Label0
	).



