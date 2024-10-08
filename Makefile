

all:

start-%: certs/dist-cert.pem
	$(MAKE) node-$*
	cd node-$* && \
	  erl -boot ./$* -proto_dist inet_tls -sname $* \
	      -ssl_dist_optfile ../ssl_dist.conf

node-%:
	mkdir $@
	escript ./genrel.escript > $@/$*.rel
	cd $@ && erlc $*.rel

setup-certs: certs/dist-ca.pem certs/dist-cert.pem

# Works with RSA
# KEY_GEN = genrsa 4096
# Works with ED25519
# KEY_GEN = genpkey -algorithm ED25519

# But *doesn't* work with edcsa!
KEY_GEN = ecparam -name prime256v1 -genkey -noout

# Distribution certificate key
certs/dist-cert.key:
	mkdir -p $(dir $@)
	openssl $(KEY_GEN) -out $@

certs/dist-cert.csr: certs/dist-cert.key certs/dist-cert.cfg
	openssl req -new -key $< -out $@ \
	    -subj "/C=SE/L=Stockholm/O=Erlang/CN=$(shell hostname -s)"

# Distribution certificate
certs/dist-cert.pem: certs/dist-cert.csr certs/dist-ca.pem certs/dist-ca.key \
			certs/dist-cert.cfg
	openssl x509 -req -in $< \
	    -CA certs/dist-ca.pem  -CAkey certs/dist-ca.key -CAcreateserial \
	    -out $@ -outform pem -days 365 -sha256 -extfile certs/dist-cert.cfg

print-dist: certs/dist-cert.pem
	openssl x509 -noout -text < $<

# Self signed CA certificate
certs/dist-ca.pem: certs/dist-ca.key
	openssl req -x509 -new -nodes -key $< -sha256 -days 730 -out $@ \
	    -subj "/C=SE/L=Stockholm/O=Erlang CA/CN=example.com"

# CA key
certs/dist-ca.key:
	mkdir -p $(dir $@)
	openssl $(KEY_GEN) -out $@

certs/dist-cert.cfg:
	@echo "" > $@
	@echo "[req]" >> $@
	@echo "distinguished_name = req_distinguished_name" >> $@
	@echo "req_extensions = req_ext" >> $@
	@echo "x509_extensions = v3_req" >> $@
	@echo "prompt = no" >> $@
	@echo "" >> $@
	@echo "[req_distinguished_name]" >> $@
	@echo "countryName = SE" >> $@
	@echo "localityName = Stockholm" >> $@
	@echo "organizationName = Erlang" >> $@
	@echo "commonName = example.com" >> $@
	@echo "" >> $@
	@echo "[req_ext]" >> $@
	@echo "subjectAltName = @alt-names" >> $@
	@echo "[v3_req]" >> $@
	@echo "keyUsage = critical, digitalSignature, keyAgreement" >> $@
	@echo "extendedKeyUsage = serverAuth" >> $@
	@echo "subjectAltName = @alt-names" >> $@
	@echo "[alt-names]" >> $@
	@echo "DNS.1 = $(shell hostname -s)" >> $@


clean:
	rm -rf certs node-*
