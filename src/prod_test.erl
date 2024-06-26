%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% 
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(prod_test). 

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").
-include("prod_test.hrl").

%% API

-export([
	 all_nodes/0
	]).

-export([

	]).

%% admin




-export([
	 start/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
		     
-record(state, {
		mode
	        
	       }).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec all_nodes() -> AllNodes::node() | [].
all_nodes()-> 
    gen_server:call(?SERVER, {all_nodes},infinity).


%%--------------------------------------------------------------------
%% @doc
%%  
%% 
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).


%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    
    {ok, #state{
    
	   },0}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.

handle_call({all_nodes}, _From, State) ->
    Reply=lib_prod_test:all_nodes(),
    {reply, Reply, State};

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.

handle_info(timeout, State) ->

    RunningSystemBootNodes=lists:sort([N||N<-?SystemBootNodes,
					  pong==net_adm:ping(N)]),
    RunningMainNodes=lists:sort([N||N<-?MainNodes,
				    pong==net_adm:ping(N)]),
    RunningApplicationNodes=lists:sort([N||N<-lib_prod_test:all_nodes(),
					   false==lists:member(N,?MainNodes),
					   pong==net_adm:ping(N)]),
    io:format("*****************  ~w~w ********************~n~n",[date(),time()]),
    
    io:format("Running system_boot Nodes  ~p~n",[RunningSystemBootNodes]),  
    io:format("Running main Nodes  ~p~n",[RunningMainNodes]),  
    io:format("RunningApplicationNodes  ~p~n",[RunningApplicationNodes]),
    spawn(fun()->loop_system_main(RunningSystemBootNodes,RunningMainNodes,RunningApplicationNodes) end),
       
    {noreply, State};


handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
loop_system_main(StateSystemBoot,StateMain,StateApplications)->
    
    RunningSystemBootNodes=lists:sort([N||N<-?SystemBootNodes,
					  pong==net_adm:ping(N)]),
    RunningMainNodes=lists:sort([N||N<-?MainNodes,
				    pong==net_adm:ping(N)]),
  
    RunningApplicationNodes=lists:sort([N||N<-lib_prod_test:all_nodes(),
					   false==lists:member(N,?MainNodes),
					   pong==net_adm:ping(N)]),
    {NewStateSystem,NewStateMain,NewStateApplications}=case {RunningSystemBootNodes==StateSystemBoot,
							     RunningMainNodes==StateMain,
							     RunningApplicationNodes==StateApplications} of
							   {true,true,true}->
							       {StateSystemBoot,StateMain,StateApplications};
							   {_,_,_}->
							       io:format("*****************  ~w~w ********************~n~n",[date(),time()]),
							       io:format("Running system_boot Nodes  ~p~n",[RunningSystemBootNodes]),  
							       io:format("Running main Nodes  ~p~n",[RunningMainNodes]),  
							       io:format("RunningApplicationNodes  ~p~n",[RunningApplicationNodes]),
							       io:format("~n"),
							       {RunningSystemBootNodes,RunningMainNodes,RunningApplicationNodes}
						       end,
    
    timer:sleep(20*1000),
    loop_system_main(NewStateSystem,NewStateMain,NewStateApplications).
