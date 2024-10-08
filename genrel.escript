#! /usr/bin/env escript

main(_) ->
    {match, [OTPVersion, ERTSVersion]} =
        re:run(erlang:system_info(system_version),
               <<"^Erlang/OTP ([0-9.]+) \\[erts-([0-9.]+)\\].*">>,
               [{capture, all_but_first, list}]),
    io:format("{release, {\"Erlang/OTP\", ~0p}, {erts, ~0p},\n",
              [OTPVersion, ERTSVersion]),
    io:format(" ~p\n}.\n", [apps()]).


apps() ->
    [begin
         application:load(A),
         {ok, V} = application:get_key(A, vsn),
         {A, V}
     end || A <- [kernel, stdlib, sasl, crypto, public_key, asn1, ssl]].
