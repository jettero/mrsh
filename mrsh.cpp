#include <signal.h>
#include <unistd.h>
#include <stdio.h>

#include "options.h"
#include "machines.h"
#include "file.h"

machines *machs;

void recv_sig(int sig) {
    printf("\nGot a %s signal, ", (sig-1) ? "cntl-c" : "hangup");
    machs->kill_all_pipes();
    printf("so all pipes were killed.\n");
    exit(1);
}

int main(int argc, char **argv) {
    options  *opts  = new options(argc, argv);
    file     *hosts = new file(opts);
              machs = hosts->read_file();

    machs->show_em();

    signal(SIGHUP,  recv_sig);
    signal(SIGINT,  recv_sig);

    for(int i=1; i<=opts->readretries; i++) {
        machs->open_all_pipes();
        printf("\nReading from the pipes (pass #%i of %i):\n", 
            i, 
            opts->readretries
        );
        if(!machs->read_all_pipes()) {
            printf("Machine queue is empty, exiting normally.\n");
            break;
        }
    }

    return 0;
}
