#include <unistd.h>
#include <stdio.h>

#include "options.h"
#include "machines.h"
#include "file.h"

int main(int argc, char **argv) {
    options  *opts  = new options(argc, argv);
    file     *hosts = new file(opts);
    machines *machs = hosts->read_file();
    int i = 1;

    machs->show_em();

    for(; i<=opts->readretries; i++) {
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
