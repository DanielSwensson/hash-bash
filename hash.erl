-module(hash).
-export([start/1,isLowerThanBar/2,test/0]).

test() ->
	hash:start(16#000001000007a47393270f686affb02be72bae461511c7dd237d22bf21364df7131feff2c8719409d792dc1d78071992a06008fa11a7084aca030357fd8fe261).

start(Bar) ->
	put("Bar", Bar),
	run().

run() ->

	Pids = spawn_loop(30),
	receive_loop(Pids).

receive_loop([Pid | Pids]) ->
	receive 
		{Pid, String, SHA} ->
			case isLowerThanBar(SHA,get("Bar")) of
				true ->
					io:format("Found low hash ~p with string ~p ~n", [SHA, String]);
				false ->
					io:format("~p : ~p ~n", [Pid, SHA]),
					exit(Pid,normal),
					Pids1 = Pids ++ spawn_loop(1),
					receive_loop(Pids1)
			end
	end.

spawn_loop(0) ->
	[];
spawn_loop(Amount) when Amount > 0 ->
	S = self(),
	Pid = spawn(fun() -> S ! sha() end),
	
	[Pid] ++ spawn_loop(Amount - 1).

isLowerThanBar(SHA,Bar) ->
	(SHA < Bar).


getRandomString() ->
	String = random(crypto:rand_uniform(1,crypto:rand_uniform(2,65)),"!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|~}"),
	case get(String) of 
		undefined ->
			put(String, "true"),
			String;
		_Any ->
			erlang:display("Already checked getting new"),
			getRandomString()
	end.



sha() ->
	String = getRandomString(),
	<<SHA:512>> = crypto:hash(sha512,String),
	{self(), String, SHA}.



random(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
			[lists:nth(random:uniform(length(AllowedChars)),
                                   AllowedChars) | Acc]
                end, [], lists:seq(1, Length)).

