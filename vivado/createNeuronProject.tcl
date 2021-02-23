# usage: vivado -mode tcl -source createBridgeProject.tcl

set_param general.maxThreads 8

create_project if_neuron_project ./if_neuron_project -part xc7z020clg484-1 -force

set_property board_part em.avnet.com:zed:part0:1.4 [current_project]

add_files {
    ../rtl/tb/if_neuron_tb.v
    ../rtl/tb/if_network_tb.v
    ../rtl/tb/if_network_test_tb.v
    ../rtl/src/spike_accumulator.v
    ../rtl/src/if_neuron.v 
    ../rtl/src/if_layer.v 
    ../rtl/src/if_layer_controller.v 
    ../rtl/src/if_network.v 
    }


move_files -fileset sim_1 [get_files  ../rtl/tb/if_neuron_tb.v]
move_files -fileset sim_1 [get_files  ../rtl/tb/if_network_tb.v]
move_files -fileset sim_1 [get_files  ../rtl/tb/if_network_test_tb.v]
add_files -fileset sim_1 -norecurse ../rtl/tb/neuron.txt
add_files -fileset sim_1 ../rtl/tb/neuron_weights/
# add_files -fileset sim_1 ../rtl/tb/neuron_test_weights/

# set_property top if_neuron_tb [get_filesets sim_1]
# set_property top if_network_tb [get_filesets sim_1]
set_property top if_network_test_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

launch_simulation

add_wave {{/if_network_tb/uut}} 
