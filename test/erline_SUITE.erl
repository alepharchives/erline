-module(erline_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0]).

-export([init_per_suite/1,
	 end_per_suite/1]).

-export([simple_line/1
	 ,seq_line_with_line/1
	 ,module_line/1
	 ,pipeline_to_pipeline/1
	 ,concurrent_line/1
	 ,seq_crash/1
	 ,concurrent_crash/1
	 ,pipeline_with_init/1
	]).

all() ->    
    [
     simple_line
     ,seq_line_with_line
     ,module_line
     ,pipeline_to_pipeline
     ,concurrent_line
     ,seq_crash
     ,concurrent_crash
     ,pipeline_with_init
    ].

% Setup & teardown
init_per_suite(Config) ->
    ok = application:start(erline),
    Config.

end_per_suite(Config) ->
    ok = application:stop(erline),
    Config.

simple_line(Config) ->
    S = erline:create(sequential, [fun(X) -> X * 10 end,
				   fun(X) -> X * 12 end], []),
    1800 = erline:sync(S, 15),
    Config.

seq_line_with_line(Config) ->
    S1 = erline:create(sequential, [fun(X) -> X * 10 end,
				    fun(X) -> X * 15 end], []),
    S2 = erline:create(sequential, [fun(X) -> X * 10 end,
				    S1,
				    fun(X) -> X * 15 end], []),
    S3 = erline:create(sequential, [fun(X) -> X * 10 end,
				   S2,
				   fun(X) -> X * 12 end], []),
    40500000 = erline:sync(S3, 15),
    Config.

module_line(Config) ->
    S = erline:create(sequential, [erline_SUITE_module1,
				   erline_SUITE_module2], []),
    <<"testaddon1addon2">> = erline:sync(S, <<"test">>),
    Config.

pipeline_to_pipeline(Config) ->
    P = erline:create(sequential, [fun(X) ->
					   X + 1
				   end,
				   fun(X) ->
					   X + 1
				   end], []),
    5 = erline:sync(P++P, 1),
    Config.

concurrent_line(Config) ->
    Tab = ets:new(test, [public]),
    S1 = erline:create(concurrent, [fun({Tab1,X}) ->
					    F = X * 10,
					    ets:insert(Tab1, {fun_1, F})
				    end,
				    fun({Tab1,X}) ->
					    F = X * 12,
					    ets:insert(Tab1, {fun_2, F})
				    end], []),
    [true,true] = erline:sync(S1, {Tab,5}),
    [{fun_1, 50}] = ets:lookup(Tab, fun_1),
    [{fun_2, 60}] = ets:lookup(Tab, fun_2),
    Config.

seq_crash(Config) ->
    S = erline:create(sequential, [erline_SUITE_module3,
				   erline_SUITE_module4], []),
    {action_error, badarg} = erline:sync(S, test),
    Config.

concurrent_crash(Config) ->
    S = erline:create(concurrent, [erline_SUITE_module3,
				   erline_SUITE_module4], []),
    Res = erline:sync(S, test),
    badarg = proplists:get_value(action_error, Res),
    "test" = proplists:get_value(module4, Res),
    Config.

%% Not sure how much I like this..should be a fun/2 in,
%% and how would this behave in "warm" pipelines?
pipeline_with_init(Config) ->
    S = erline:create(sequential, [fun([output, X]) ->
					   X+1
				   end,
				   fun([output, X]) ->
					   X+1
				   end], [{on_start, fun() ->
							     output
						     end},
					  {on_end, fun(output) ->
							   ok
						   end}]),
    3 = erline:sync(S, 1),
    Config.
