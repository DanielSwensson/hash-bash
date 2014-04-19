-module(hash).
-export([start/1,test/0]).

test() ->
	hash:start(16#000100000007a47393270f686affb02be72bae461511c7dd237d22bf21364df7131feff2c8719409d792dc1d78071992a06008fa11a7084aca030357fd8fe261).

start(Bar) ->
	spawn(fun() -> run(Bar) end).

run(Bar) ->

	Pids = spawn_loop(8,[],dict:new()),
	receive_loop(Pids,Bar,0,dict:new()).

receive_loop(Pids,Bar,Count,Strings) ->
	receive 
		{Pid, String, SHA} ->
			case (SHA < Bar) of
				true ->
					lists:map(fun(P) -> exit(P,normal) end, Pids),
					io:format("Found low hash ~p with string ~p ~n After ~p attempts ~n", [SHA, String,Count + 1]),
					exit(normal);
				false ->
					%io:format("~p : ~p ~n", [Pid, SHA]),
					exit(Pid,normal),
					Strings1 = dict:store(String, 1, Strings),
					PidsDeleted = lists:delete(Pid,Pids),
					Pids1 = PidsDeleted ++ spawn_loop(1,[],Strings1),
					receive_loop(Pids1,Bar,Count + 1,Strings1)
			end;

		status ->
			io:format("Count: ~p ~n",[Count]),
			receive_loop(Pids,Bar,Count,Strings);

		kill ->
			erlang:display("Dying"),
			lists:map(fun(P) -> exit(P,normal) end, Pids),
			exit(normal)
	end.

spawn_loop(0,Pids,_Strings) ->
	Pids;
spawn_loop(Amount,Pids,Strings) when Amount > 0 ->
	S = self(),
	Pids1 = Pids ++ [spawn(fun() -> S ! sha(Strings) end)],
	spawn_loop(Amount - 1,Pids1,Strings).


getRandomString(Strings) ->
	String = random(crypto:rand_uniform(1,crypto:rand_uniform(2,65)),"!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|~}"),
	case dict:is_key(String,Strings) of 
		false ->
			String;
		true ->
			getRandomString(Strings)
	end.



sha(Strings) ->
	String = getRandomString(Strings),
	<<SHA:512>> = crypto:hash(sha512,String),
	{self(), String, SHA}.



random(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
			[lists:nth(random:uniform(length(AllowedChars)),
                                   AllowedChars) | Acc]
                end, [], lists:seq(1, Length)).

