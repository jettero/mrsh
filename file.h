#ifndef NOREGEXP
    #include <regex.h>
#endif

class file {
    private:
        #ifndef NOREGEXP
        int matches(const char *mname, const char *regexp, regex_t *re);
        #endif
        options *opts;

    public:
        machines *read_file();
        file(options *o);
};
