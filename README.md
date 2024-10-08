# Intro

This repository contains everything you need to setup nodes running
distributed Erlang over TLS (on the same host). It is only intended
for demonstration purposes, and specifically I set it up to hunt down
an incompatibility between different OTP versions.

To start a node use `make start-<nodename>`, e.g. `make start-a` which
will generate the necessary start scripts, certificates, and ssl dist
configuration, and then start the node.

To try with different versions, make sure you have your path setup to
have the version of `erl`, `erlc`, and `escript` you want to try with
_before_ invoking `make start-<nodename>`.

# Erlang distribution over TLS incompatibility

You need an OTP version 26.2.5 and 26.2.5.3 or 27.1

Start node a using 26.2.5:

```
% source .../OTP-26.2.5/activate
% make start-a
...
Erlang/OTP 26 [erts-14.2.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Eshell V14.2.5 (press Ctrl+G to abort, type help(). for help)
(a@nephele)1>
```

Now start node b using the same version:

```
% source .../OTP-26.2.5/activate
% make start-b
...
Erlang/OTP 26 [erts-14.2.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Eshell V14.2.5 (press Ctrl+G to abort, type help(). for help)
(b@nephele)1> net:ping(a@nephele).
pong
(b@nephele)2>
```

Now start node c using 26.2.5.3

```
% source .../OTP-26.2.5.3/activate
% make start-c
...
Erlang/OTP 26 [erts-14.2.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Eshell V14.2.5 (press Ctrl+G to abort, type help(). for help)
(c@nephele)1> net:ping(a@nephele).
=NOTICE REPORT==== 8-Oct-2024::17:31:46.514684 ===
TLS client: In state hello received SERVER ALERT: Fatal - Insufficient Security

pang
(c@nephele)2>
```

You will also see at node a:

```
=NOTICE REPORT==== 8-Oct-2024::17:30:06.628160 ===
TLS server: In state hello at ssl_handshake.erl:1740 generated SERVER ALERT: Fatal - Insufficient Security
 - no_suitable_signature_algorithm
```

Now start node d using 27.1, same problem here:

```
% source .../OTP-27.1/activate
% make start-d
...
Erlang/OTP 26 [erts-14.2.5] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Eshell V14.2.5 (press Ctrl+G to abort, type help(). for help)
(d@nephele)1> net:ping(a@nephele).
=NOTICE REPORT==== 8-Oct-2024::17:31:46.514684 ===
TLS client: In state hello received SERVER ALERT: Fatal - Insufficient Security

pang
(d@nephele)2>
```

# Working variant using rsa

In the [Makefile](./Makefile) change KEY_GEN to use `genrsa`:

```Makefile
# Works with RSA
KEY_GEN = genrsa 4096
# Works with ED25519
# KEY_GEN = genpkey -algorithm ED25519

# But *doesn't* work with edcsa!
# KEY_GEN = ecparam -name prime256v1 -genkey -noout
```

Stop all nodes, do a `make clean` and re-try the experiment - now it
works as expected.
