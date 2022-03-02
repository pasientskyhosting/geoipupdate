ifndef BUILDDIR
BUILDDIR=build
endif

ifndef DOCKERDIR
DOCKERDIR=docker
endif

ifndef CONFFILE
ifeq ($(OS),Windows_NT)
CONFFILE=%SystemDrive%\ProgramData\MaxMind\GeoIPUpdate\GeoIP.conf
else
CONFFILE=/usr/local/etc/GeoIP.conf
endif
endif

ifndef DATADIR
ifeq ($(OS),Windows_NT)
DATADIR=%SystemDrive%\ProgramData\MaxMind\GeoIPUpdate\GeoIP
else
DATADIR=/usr/local/share/GeoIP
endif
endif

ifeq ($(OS),Windows_NT)
MAYBE_CR=\r
endif

ifndef VERSION
VERSION=unknown
endif

all: \
	$(DOCKERDIR)/geoipupdate \
	$(BUILDDIR)/geoipupdate \
	data

data: \
	$(BUILDDIR)/GeoIP.conf \
	$(BUILDDIR)/GeoIP.conf.md \
	$(BUILDDIR)/geoipupdate.md \
	$(BUILDDIR)/GeoIP.conf.5 \
	$(BUILDDIR)/geoipupdate.1

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/geoipupdate: $(BUILDDIR)
	(cd cmd/geoipupdate && go build -ldflags '-X main.defaultConfigFile=$(CONFFILE) -X main.defaultDatabaseDirectory=$(DATADIR) -X "main.version=$(VERSION)"')
	cp cmd/geoipupdate/geoipupdate $(BUILDDIR)

$(DOCKERDIR)/geoipupdate:
	(cd cmd/geoipupdate && GOOS=linux GOARCH=amd64 go build -ldflags '-X main.defaultConfigFile=$(CONFFILE) -X main.defaultDatabaseDirectory=$(DATADIR) -X "main.version=$(VERSION)"')
	cp cmd/geoipupdate/geoipupdate $(DOCKERDIR)

$(BUILDDIR)/GeoIP.conf: $(BUILDDIR) conf/GeoIP.conf.default
	sed -e 's|CONFFILE|$(CONFFILE)|g' -e 's|DATADIR|$(DATADIR)|g' -e 's|$$|$(MAYBE_CR)|g' conf/GeoIP.conf.default > $(BUILDDIR)/GeoIP.conf

$(BUILDDIR)/GeoIP.conf.md: $(BUILDDIR) doc/GeoIP.conf.md
	sed -e 's|CONFFILE|$(CONFFILE)|g' -e 's|DATADIR|$(DATADIR)|g' -e 's|$$|$(MAYBE_CR)|g' doc/GeoIP.conf.md > $(BUILDDIR)/GeoIP.conf.md

$(BUILDDIR)/geoipupdate.md: $(BUILDDIR) doc/geoipupdate.md
	sed -e 's|CONFFILE|$(CONFFILE)|g' -e 's|DATADIR|$(DATADIR)|g' -e 's|$$|$(MAYBE_CR)|g' doc/geoipupdate.md > $(BUILDDIR)/geoipupdate.md

$(BUILDDIR)/GeoIP.conf.5: $(BUILDDIR)/GeoIP.conf.md  $(BUILDDIR)/geoipupdate.md
	dev-bin/make-man-pages.pl "$(BUILDDIR)"

$(BUILDDIR)/geoipupdate.1: $(BUILDDIR)/GeoIP.conf.5

docker: clean $(DOCKERDIR)/geoipupdate docker-push
	docker build -f $(DOCKERDIR)/Dockerfile -t pasientskyhosting/geoipupdate .

docker-push:
	docker push pasientskyhosting/geoipupdate

clean:
	rm -rf $(BUILDDIR)/GeoIP.conf \
		   $(BUILDDIR)/GeoIP.conf.md \
		   $(BUILDDIR)/geoipupdate \
		   $(BUILDDIR)/geoipupdate.md \
		   $(BUILDDIR)/GeoIP.conf.5 \
		   $(BUILDDIR)/geoipupdate.1 \
			 $(DOCKERDIR)/geoipupdate
