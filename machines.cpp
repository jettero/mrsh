#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>

#include "machines.h"

#define J_EOF      1
#define J_ERROR   -1
#define J_VALID    0
#define J_NO_PIPE -6

int opened_pipes;  /* this is embarrasing */

// single machine
machine::machine(char n[80], options *o) {
    mypipe        = 0;
    opts          = o;
    mykid         = 0;
    has_been_read = 0;
    opened_pipes  = 0;
    strcpy(name, n);
}

     machine::~machine()  { kill_pipe(); }
int  machine::has_pipe()  { return (mypipe) ? 1:0; }
int  machine::was_read()  { return has_been_read; }
void machine::mark_read() { has_been_read = 1; }

void machine::kill_pipe() { 
    if(mypipe) {
        pclose(mypipe);
        mypipe = 0;  /* not actually redundant */
        opened_pipes--;
    }
}


void machine::start_pipe() {
    char full_command[510];

    sprintf(full_command, "%s %s \"%s\" 2>&1", 
        opts->rshCommand, 
        name,
        opts->command
    );
    if (!mypipe && opts->maxpopen > opened_pipes && !has_been_read) {
        mypipe = popen(full_command, "r");
        if(mypipe) {
            fcntl(fileno(mypipe), F_SETFL, O_NONBLOCK);
            opened_pipes++;
        }
    }
}

int machine::read_from_pipe(char buf[255]) {
    int ret = J_VALID;

    if(mypipe) {
        clearerr(mypipe);
        fgets(buf, opts->get_win_width(), mypipe);

        ret = (ferror(mypipe)) ? J_ERROR : ret;
        ret = (feof(  mypipe)) ? J_EOF   : ret;
    } else { 
        ret = J_NO_PIPE;
    }

    return ret;
}

// all machines
machines::machines(options *o) {
    opts = o;
    listHead = 0;
}

void machines::open_all_pipes() {
    int counter  = 0;
    machine *tmp = listHead;

    while(tmp) {
        if(!tmp->has_pipe())
            tmp->start_pipe();
        tmp = tmp->mykid;
    }
}

int machines::read_all_pipes() {
    machine *tmp = listHead;
    char buf[255];
    int count = 0;
    int ret;
    int timeoutcount  = 0;
    int timeoutmax    = opts->timeout;
    int littlelinelen = 0;

    while(tmp) {
        if(tmp->was_read()) {
            tmp = tmp->mykid;
            continue;
        } else {
            count++;
        }
        if(!tmp->has_pipe()) {
            tmp = tmp->mykid;
        /*    printf("[no pipe yet]\n");   Future switch.... */
            continue;
        }
        if(opts->singleline) {
           printf("%s: ", tmp->name);
           littlelinelen = (opts->get_win_width()-1) - strlen(tmp->name)-1;
        } else {
            printf("\n%s:\n", tmp->name);
        }
        while( (ret = tmp->read_from_pipe(buf)) != J_EOF) {
            if(ret == J_VALID) {
                if(strlen(buf)) {
                    if(opts->singleline) {
                        if(!tmp->was_read()) {
                            printf("%*.*s", littlelinelen, littlelinelen, buf);
                        }
                    } else {
                        printf("%s", buf);
                    }
                    tmp->mark_read();
                }
                timeoutcount=0;
            } else {
                sleep(1);
                timeoutcount++;
                if(timeoutcount >= timeoutmax) {
                    timeoutcount = 0;
                    printf("[timeout]\n");
                    break;
                }
            }
        }
        if(ret == J_EOF) {
            tmp->kill_pipe();
            if(!tmp->was_read()) {
                printf("[no output]\n");
                tmp->mark_read();
            }
        }
        tmp = tmp->mykid;
    }

    return count;
}

void machines::show_em() {
    machine *tmp = listHead;
    int counter = 10;

    printf("Machines: ");
    while(tmp) {
        counter += strlen(tmp->name) +2;
        if(counter > opts->get_win_width()) {
            counter = 10;
            printf("\n          ");
        }
        printf("%s ", tmp->name);
        tmp = tmp->mykid;
    }
    printf("\n");
}

void machines::push(char name[80]) {
    machine *tmp  = listHead;
    machine *otmp = 0;

    while(tmp) {
        otmp = tmp;
        tmp  = tmp->mykid;
    }

    if(otmp) otmp->mykid = new machine(name, opts);
    else     listHead    = new machine(name, opts);
}
