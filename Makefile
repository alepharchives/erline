REBAR=./rebar

get_deps:
	@$(REBAR) get-deps

compile: get_deps
	@$(REBAR) compile

clean:
	@$(REBAR) clean

eunit: clean compile
	mv rebar.config rebar.prod.config
	mv rebar.test.config rebar.config
	@$(REBAR) get_deps compile eunit skip_deps=true
	mv rebar.config rebar.test.config
	mv rebar.prod.config rebar.config

ct: clean compile
	mv rebar.config rebar.prod.config
	mv rebar.test.config rebar.config
	@$(REBAR) get_deps compile ct skip_deps=true
	mv rebar.config rebar.test.config
	mv rebar.prod.config rebar.config