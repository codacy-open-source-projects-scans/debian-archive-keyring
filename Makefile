TRUSTED-LIST := $(patsubst active-keys/add-%,trusted.pgp/debian-archive-%.pgp,$(wildcard active-keys/add-*))
TMPRING := trusted.pgp/build-area

GPG_OPTIONS := --no-options --no-default-keyring --no-auto-check-trustdb --trustdb-name ./trustdb.gpg

build: keyrings/debian-archive-keyring.pgp keyrings/debian-archive-removed-keys.pgp $(TRUSTED-LIST)

keyrings/debian-archive-keyring.pgp: active-keys/index
	jetring-build -I $@ active-keys
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@
	ln -s $(notdir $@) $(patsubst %.pgp,%.gpg,$@)

keyrings/debian-archive-removed-keys.pgp: removed-keys/index
	jetring-build -I $@ removed-keys
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@
	ln -s $(notdir $@) $(patsubst %.pgp,%.gpg,$@)

$(TRUSTED-LIST) :: trusted.pgp/debian-archive-%.pgp : active-keys/add-% active-keys/index
	mkdir -p $(TMPRING) trusted.pgp
	grep -F $(shell basename $<) -- active-keys/index > $(TMPRING)/index
	cp $< $(TMPRING)
	jetring-build -I $@ $(TMPRING)
	rm -rf $(TMPRING)
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@
	ln -s $(notdir $@) $(patsubst %.pgp,%.gpg,$@)

clean:
	rm -f keyrings/debian-archive-keyring.pgp \
		keyrings/debian-archive-keyring.pgp~ \
		keyrings/debian-archive-keyring.pgp.lastchangeset \
		keyrings/debian-archive-keyring.gpg \
		$(EOL)
	rm -f keyrings/debian-archive-removed-keys.pgp \
		keyrings/debian-archive-removed-keys.pgp~ \
		keyrings/debian-archive-removed-keys.pgp.lastchangeset \
		keyrings/debian-archive-removed-keys.gpg \
		$(EOL)
	rm -f keyrings/team-members.pgp \
		keyrings/team-members.pgp~ \
		keyrings/team-members.pgp.lastchangeset
	rm -rf $(TMPRING) trusted.pgp trustdb.gpg
	rm -f keyrings/*.cache

install: build
	install -d $(DESTDIR)/usr/share/keyrings/
	cp trusted.pgp/debian-archive-*.pgp $(DESTDIR)/usr/share/keyrings/
	cp -a trusted.pgp/debian-archive-*.gpg $(DESTDIR)/usr/share/keyrings/
	cp keyrings/debian-archive-keyring.pgp $(DESTDIR)/usr/share/keyrings/
	cp -a keyrings/debian-archive-keyring.gpg $(DESTDIR)/usr/share/keyrings/
	cp keyrings/debian-archive-removed-keys.pgp $(DESTDIR)/usr/share/keyrings/
	cp -a keyrings/debian-archive-removed-keys.gpg $(DESTDIR)/usr/share/keyrings/
	install -d $(DESTDIR)/etc/apt/trusted.gpg.d/
	cp $(shell find apt-trusted-asc/ -name '*.asc' -type f) $(DESTDIR)/etc/apt/trusted.gpg.d/

.PHONY: clean build install
