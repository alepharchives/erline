-module(erline_test).
-include("../src/erline.hrl").
-include_lib("eunit/include/eunit.hrl").

erline_test_() ->
    {setup,
     fun() ->
	     application:start(meck),
	     application:start(erline)
     end,
     fun(_Pid) ->
	     application:stop(meck),
	     application:stop(erline)
     end,
     [
      {"check a spec", ?_test(t_check_spec())}
     ]}.

% Tests
t_check_spec() ->
    lists:foreach(fun(ModuleName) ->
			  meck:new(ModuleName)
		  end, [module1,module2,module3,module4,
			module5,module6]),
    
    S = {sequential,[module1,
		     {sequential, [module2]}
		    ],
	 {parallel,[module3,
		    fun(D) -> D end,
		    module4],
	  {sequential,[module5]}
	 },
	 {finally, [module6]}
	},
    ?assertMatch({pipeline,sequential,undefined,
		  [module1,
		   {pipeline,sequential,[inherit],[module2],undefined,undefined}],
		  {pipeline,parallel,
		   [inherit],
		   [module3,F,module4],
		   {pipeline,sequential,
		    [inherit],
		    [module5],
		    undefined,undefined},
		   undefined},
		  {pipeline,finally,[inherit],[module6],undefined,undefined}}
		 when is_function(F)
		 , erline:prepare(S)).
