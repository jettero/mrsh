#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "options.h"

#include "defaults.h"

int options::get_win_width() {
    return (crappy) ? 80:wsize.ws_col;
}


void options::set_defaults() {
    MaxMachines = MAXMACHINES;
    timeout     = TIMEOUT;
    singleline  = SINGLELINE;
    readretries = PASSES;
    maxpopen    = MAXPIPES;

    #ifndef NOREGEXP
    strcpy(MachineMask, MASK);
    #endif
    strcpy(HostsFile,   MACHINELIST);
    strcpy(command,     CMD);
    strcpy(rshCommand,  SHL);
}

void options::show_help() {
    char str[160];
    int l,i,j;

    printf("Mrsh version %s was compiled on %s.\n", 
        VERSION, BDATE);
    printf("Usage: mrsh [options] -c \"command\"\n\n");

    printf(" -n: Maximum number of machines upon which to execute. [%i]\n\n", 
        MaxMachines);
                
    printf(" -t: The number of seconds mrsh will wait before it gives up \n");
    printf("     and tries a different pipe [%i].\n\n", timeout);
                
    #ifndef NOREGEXP
    printf(" -m: A regexp matching word, to specify upon which host to\n");
    printf("     execute [%s].\n\n", MachineMask);
    #endif
                
    printf(" -H: The file that contains the names of hosts against which\n");
    printf("     mrsh matches [%s].\n\n", HostsFile); 
    printf(" -c: The command you wish to execute [%s].\n\n", command);
                
    printf(" -s: The command with which you wish to remotely\n");
    strcpy(str,"     shell ["); strcat(str,rshCommand); strcat(str, "].\n\n");
    if( (l=strlen(str)) > 79) {
        for(i=l+5; i>80 || str[i-5]!=' '; i--) 
            str[i] = str[i-5];
        str[i-5]='\n';
        for(j=-4; j<1; j++) 
            str[i+j] = ' ';
    }
    printf(str);
                
    printf(" -1: Output should be formatted for a single line [%s].\n\n", 
        (singleline) ? "yes":"no"
    );
                
    printf(" -2: Output should be formatted for many lines [%s].\n\n",
        (!singleline) ? "yes":"no"
    );

    printf(" -r: The number of times to re-try reading from the \n");
    printf("      pipes (it does give up if this is too high) [%i].\n\n", 
        readretries);
            
    printf(" -p: The maximum number of pipes mrsh can open in a \n");
    printf("      single run [%i].\n\n", maxpopen);
                               
    exit(0);
}

options::options(int argc, char **argv) {
    char c=0;
    int i;
    int atleast1 = 0;
    int idiot1 = 0;
    int idiot2 = 0;
    int option_index = 0;

    set_defaults();

    for(;c!=-1;) {
        c = getopt(argc, argv, "12hn:t:m:H:c:s:r:p:");
        if(c!=-1) atleast1=1;
        switch(c) {
            case '?': exit(1);
            case 'h': show_help();

            case 'n': MaxMachines = atoi(optarg); break;
            case 't': timeout     = atoi(optarg); break;
            case 'r': readretries = atoi(optarg); break;
            case 'p': maxpopen    = atoi(optarg); break;

            #ifndef NOREGEXP
            case 'm': strcpy(MachineMask, optarg); break;
            #endif
            case 'H': strcpy(HostsFile,   optarg); break;
            case 'c': strcpy(command,     optarg); break;
            case 's': strcpy(rshCommand,  optarg); break;

            case '1': singleline = 1; idiot1 = 1; break;
            case '2': singleline = 0; idiot2 = 1; break;
        }
        if(idiot1 && idiot2) {
            printf("Warning:  You are an idiot.\n");
            exit(1);
        }
    }
    if(!atleast1) show_help();

    /* grab the window attribs */
    if (ioctl(1, TIOCGWINSZ, (char *) &wsize) < 0) {
        crappy = 1;
    } else {
        crappy = 0;
    }

    if(get_win_width() > 240) {
        printf("Your window is just too damn big.  Tell \n");
        printf("jettero@cs.wmich.edu that this frustraites you, and he'll fix it.\n");
        exit(1);
    }
}
