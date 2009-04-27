#ifndef ___machineH
#define ___machineH

#include <stdio.h>

#include "options.h"

class machine {
    private:
        FILE * mypipe;
        options *opts;
        int has_been_read;

    public:
        int  has_pipe();
        int  was_read();
        void mark_read();
        void kill_pipe();
        machine *mykid;
        char name[80];

        machine(char n[80], options *o);
        ~machine();
        void start_pipe();
        int read_from_pipe(char buf[255]);
};

class machines {
    private:
        machine *listHead;
        options *opts;

    public:
        void open_all_pipes();
        void kill_all_pipes();
         int read_all_pipes();
        void push(char name[80]);
        void show_em();

        machines(options *o);
};

#endif
