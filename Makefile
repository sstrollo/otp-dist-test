

all:

start-%:
	$(MAKE) node-$*
	cd node-$* && \
	  erl -boot ./$* -proto_dist inet_tls -sname $* -ssl_dist_optfile ../ssl_dist.conf

node-%:
	mkdir $@
	escript ./genrel.escript > $@/$*.rel
	cd $@ && erlc $*.rel
	$(MAKE) node-$*/dist-cert.pem

setup-certs: certs/dist-ca.pem certs/dist-cert.pem


certs/dist-cert.key:
	mkdir -p $(dir $@)
	openssl genrsa -out $@ 4096

certs/dist-cert.csr: certs/dist-cert.key certs/req.cfg certs/dist-cert.cfg
	: # openssl req -new -key $< -out $@ -config certs/req.cfg
	openssl req -new -key $< -out $@ -config certs/dist-cert.cfg

certs/dist-cert.pem: certs/dist-cert.csr certs/dist-ca.pem certs/dist-ca.key certs/dist-cert.cfg
	openssl x509 -req -in $< \
	    -CA certs/dist-ca.pem  -CAkey certs/dist-ca.key -CAcreateserial \
	    -out $@ -outform pem -days 365 -sha256 -extfile certs/dist-cert.cfg

print-dist: certs/dist-cert.pem
	openssl x509 -noout -text < $<

certs/dist-ca.pem: certs/dist-ca.key certs/req.cfg
	openssl req -x509 -new -nodes -key $< -sha256 -days 730 -config certs/req.cfg -out $@

certs/dist-ca.key:
	mkdir -p $(dir $@)
	: # openssl genrsa -des3 -out $@ 4096
	openssl genrsa -out $@ 4096

certs/req.cfg:
	@echo "" > $@
	@echo "[req]" >> $@
	@echo "distinguished_name = req_distinguished_name" >> $@
	@echo "prompt = no" >> $@
	@echo "" >> $@
	@echo "[req_distinguished_name]" >> $@
	@echo "countryName = SE" >> $@
	@echo "localityName = Stockholm" >> $@
	@echo "organizationName = Erlang" >> $@
	@echo "commonName = example.com" >> $@

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
	@echo "subjectAltName = @alt-names" >> $@
	@echo "[alt-names]" >> $@
	@echo "DNS.1 = $(shell hostname -s)" >> $@


clean:
	rm -rf certs node-*
