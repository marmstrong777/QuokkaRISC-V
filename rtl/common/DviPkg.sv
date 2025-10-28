// REFACTOR Maybe just make a package that encompasses all top level peripheral interfaces e.g. dvi, gpio, etc.
package DviPkg;

    typedef struct {
        logic red, green, blue, clk;
    } dvi_st;
endpackage
