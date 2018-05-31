
set project_name "frame_resize"
set PartDev      "xc7z020clg484-1"

set TclPath      [file dirname [file normalize [info script]]]
set ProjectPath  $TclPath
put $ProjectPath

create_project -force $project_name $ProjectPath -part xc7z020clg484-1

add_files -norecurse -force $ProjectPath/verilog_files/frame_resize.v $ProjectPath/verilog_files/BRAM_Memory_24x24.v
update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -force $ProjectPath/verilog_files/frame_generator.v $ProjectPath/verilog_files/frame_resize_tb.v
update_compile_order -fileset sim_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $ProjectPath/Rdata.txt $ProjectPath/Gdata.txt $ProjectPath/Bdata.txt
update_compile_order -fileset sim_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $ProjectPath/parameters.vh
update_compile_order -fileset sim_1

set_property file_type SystemVerilog [get_files $ProjectPath/verilog_files/frame_resize.v]
set_property file_type SystemVerilog [get_files $ProjectPath/verilog_files/BRAM_Memory_24x24.v]
set_property file_type SystemVerilog [get_files $ProjectPath/verilog_files/frame_generator.v]
set_property file_type SystemVerilog [get_files $ProjectPath/verilog_files/frame_resize_tb.v]

launch_simulation
run all
