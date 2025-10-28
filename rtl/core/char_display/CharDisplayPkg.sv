package CharDisplayPkg;

    typedef struct {
        logic        hsync, vsync, frame, active; 
        // REFACTOR Vector lengths should be named constants.
        logic [11:0] pos_x, pos_y;
    } video_timings_st;


    typedef struct {
        logic [7:0] red, green, blue;
    } rgb_st;
endpackage