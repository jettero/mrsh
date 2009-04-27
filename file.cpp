#include <stdio.h>
#ifndef NOREGEXP
    #include <regex.h>
#endif

#include "options.h"
#include "machines.h"
#include "file.h"

machines *file::read_file() {
    machines *m = new machines(opts);
    char mname[80];
    #ifndef NOREGEXP
    regex_t re;
    #endif
    int count = 0;

    FILE *f = fopen(opts->HostsFile, "r");

    if(!f) {
        printf("Exactly what file would you like me to get host names ");
        printf("from?  You probably want to use (-H).\n");
        exit(1);
    }

    while(1==fscanf(f, "%s\n", mname) && count < opts->MaxMachines) {
        #ifndef NOREGEXP
        if(matches(mname, opts->MachineMask, &re)) {
        #endif    
            m->push(mname);
        #ifndef NOREGEXP
            count ++;
        }
        #endif    
    }

    #ifndef NOREGEXP
    regfree(&re);
    #endif 
    fclose(f);

    return m;
}

#ifndef NOREGEXP
int file::matches(const char *mname, const char *regexp, regex_t *re) {
    int status;

    char buf[256];

    if((status=regcomp(re, regexp, REG_EXTENDED)) != 0) {
        regerror(status, re, buf, 256);
        printf("regexp error = %s\n", buf);
        exit(1);
    }

    status = regexec(re, mname, 0, NULL, 0);

    return !status;
}
#endif 

file::file(options *o) {
    opts = o;
}
