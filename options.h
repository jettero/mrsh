#ifndef __optionsH
#define __optionsH

#include <stdio.h>
#include <termios.h>
#include <sys/ioctl.h>

class options {
    private:
        int crappy;
        struct winsize wsize;
        void set_defaults();
        void show_help();

    public:
        int MaxMachines;
        int singleline;
        int timeout;
        int readretries;
        int maxpopen;

        char MachineMask[255];
        char HostsFile  [255];

        char command    [255];
        char rshCommand [255];

        options(int argc, char** argv);

        get_win_width();
};

#endif
