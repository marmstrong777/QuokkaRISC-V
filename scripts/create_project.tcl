set proj_name "QuokkaRv"
set proj_dir  "./build"

create_project $proj_name $proj_dir -part xc7z020clg400-1 -force

#add_files -fileset sources_1 [glob ./rtl/**/*.sv]

# Top RTL
add_files -fileset sources_1 [glob ./rtl/top/*.sv]

# Core RTL from subdirectories
foreach dir [glob ./rtl/core/* -type d] {
    add_files -fileset sources_1 [glob $dir/*.sv]
}

# Common packages
add_files -fileset sources_1 [glob ./rtl/common/*.sv]

# Testbenches
add_files -fileset sim_1 [glob ./sim/tb/*.sv]

# Wave config
add_files -fileset sim_1 [glob ./sim/waves/*.wcfg]

set_property file_type {SystemVerilog} [get_files *.sv]

# Add constraints
add_files -fileset constrs_1 ./constr/top.xdc

# Add IP
# FIXME Ip xci files reference a gen folder in home directory.
# REFACTOR Manually adding each bit of ip, better way to do this?
add_files -fileset sources_1 ./ip/clk_gen/clk_gen.xci
generate_target all [get_files ./ip/clk_gen/clk_gen.xci]
add_files -fileset sources_1 ./ip/uart_fifo_async/uart_fifo_async.xci
generate_target all [get_files ./ip/uart_fifo_async/uart_fifo_async.xci]

# REFACTOR Should the program mem files be stored in version control?
# Add mem files
add_files -fileset sources_1 [glob ./mem/*.mem]

# Set top module
set_property top Top [current_fileset]

# TODO Way to run vivado without it spitting out a bunch of logs and trash files all over the root directory.