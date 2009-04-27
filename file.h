#include <regex.h>

class file {
    private:
        int matches(const char *mname, const char *regexp, regex_t *re);
        options *opts;

    public:
        machines *read_file();
        file(options *o);
};
