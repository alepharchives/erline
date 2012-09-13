-module(erline).
-export([prepare/2,
	 prepare/1,
	 sync/2,
	 async/2]).
-include("erline.hrl").

prepare(Pipeline) ->
    prepare(Pipeline, undefined).

prepare(Pipeline, Opts) ->
    [#pipeline{type=element(1, Pipeline),
	       actions=validate_actions(element(2, Pipeline), []),
	       opts=Opts}].

validate_actions([], Res) ->
    Res;
validate_actions([Function|Rest], Res) when is_function(Function) ->
    validate_actions(Rest, Res++[Function]);
validate_actions([Module|Rest], Res) when is_atom(Module) ->
    case erlang:module_loaded(Module) of
	true -> validate_actions(Rest, Res++[Module]);
	_ -> erlang:error(badarg)
    end;
validate_actions([Pipeline|Rest], Res) when is_tuple(Pipeline) ->
    validate_actions(Rest, Res++[prepare(Pipeline, inherit)]).

sync(Pipelines, Input) ->
    Ref = async(Pipelines, Input),
    receive
	{Ref, Res} ->
	    Res
    end.

async([#pipeline{}|_]=Pipelines, Input) ->
    erline_manager_sup:start_pipeline(self(), Pipelines, Input).

