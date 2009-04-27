install_dir=/usr/local/sysadmin/bin2
installed_owner=0
installed_group=sysadmin
installed_perms=110

###############################################################################

name=mrsh
version=1.1a
lname=${name}-${version}
ppacked=${lname}.tar
fpacked=${lname}.tar.gz

headers=options.h machines.h options.h file.h

all: ${name}

wpack: pack
	[ ${USER} = jettero ] && \
            mv ../${fpacked} /home/jettero/www/${name}/${fpacked}
pack:
	make clean
	cd ..; tar -cf ${ppacked} ${name}
	cd ..; gzip ${ppacked}
	cd ..; chmod 644 ${fpacked}

objs=options.o machines.o file.o ${name}.o

file.o:         file.cpp ${headers}
options.o:   options.cpp ${headers} defaults.h
machines.o: machines.cpp ${headers}
${name}.o:   ${name}.cpp ${headers}

${name}: ${objs}
	g++ -o ${name} ${objs}

clean:
	rm -f ${name} *.o core fil

install: all
	sudo install -s -o 0 -g sysadmin -m 110 ${name} ${install_dir}/${name}
	make pack
