DIR := ${CURDIR}
export PATH := /usr/local/opt/qt@5/bin:$(PATH)
# Some users on old versions of MacOS 10.13 run into the error:
# dyld: cannot load 'PathOfBuilding' (load command 0x80000034 is unknown)
#
# It looks like 0x80000034 is associated with the fixup_chains optimization
# that improves startup time:
# https://www.emergetools.com/blog/posts/iOS15LaunchTime
#
# For compatibility, we disable that using the flag from this thread:
# https://github.com/python/cpython/issues/97524
export LDFLAGS := -L/usr/local/opt/qt@5/lib -Wl,-no_fixup_chains
export CPPFLAGS := -I/usr/local/opt/qt@5/include
export PKG_CONFIG_PATH := /usr/local/opt/qt@5/lib/pkgconfig

all: frontend pob
	pushd build; \
	ninja install; \
	popd; \
	macdeployqt ${DIR}/PathOfBuilding.app; \
	cp ${DIR}/Info.plist.sh ${DIR}/PathOfBuilding.app/Contents/Info.plist; \
	echo 'Finished'

pob: load_pob luacurl frontend
	rm -rf PathOfBuildingBuild; \
	cp -rf PathOfBuilding PathOfBuildingBuild; \
	pushd PathOfBuildingBuild; \
	bash ../editPathOfBuildingBuild.sh; \
	popd

frontend:
	arch=x86_64 meson -Dbuildtype=release --prefix=${DIR}/PathOfBuilding.app --bindir=Contents/MacOS build

# We checkout the latest version.
load_pob:
	git clone https://github.com/PathOfBuildingCommunity/PathOfBuilding.git; \
	pushd PathOfBuilding; \
	git fetch; \
	popd

luacurl:
	git clone --depth 1 https://github.com/Lua-cURL/Lua-cURLv3.git; \
	bash editLuaCurlMakefile.sh; \
    pushd Lua-cURLv3; \
	make; \
	mv lcurl.so ../lcurl.so; \
	popd

# curl is used since mesonInstaller.sh copies over the shared library dylib
# dylibbundler is used to copy over dylibs that lcurl.so uses
tools:
	arch --x86_64 brew install qt@5 luajit zlib meson curl dylibbundler gcc@12 luarocks; \
	sudo luarocks install luautf8 --lua-version 5.1; \
	cp ~/.luarocks/lib/lua/5.1/lua-utf8.so .

# We don't usually modify the PathOfBuilding directory, so there's rarely a
# need to delete it. We separate it out to a separate task.
fullyclean: clean
	rm -rf PathOfBuilding

clean:
	rm -rf PathOfBuildingBuild PathOfBuilding.app Lua-cURLv3 lcurl.so build
