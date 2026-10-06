open_project ./pcileech_75t484_x1/pcileech_75t484_x1.xpr
set ip [get_ips pcie_7x_0]

puts "=== BEFORE ==="
puts "Device_Port_Type: [get_property CONFIG.Device_Port_Type $ip]"
puts "Vendor_ID: [get_property CONFIG.Vendor_ID $ip]"
puts "Device_ID: [get_property CONFIG.Device_ID $ip]"

set_property -dict [list \
    CONFIG.Vendor_ID                {8086} \
    CONFIG.Device_ID                {1533} \
    CONFIG.Subsystem_Vendor_ID      {8086} \
    CONFIG.Subsystem_ID             {0758} \
    CONFIG.Class_Code_Base          {02} \
    CONFIG.Class_Code_Sub           {00} \
    CONFIG.Class_Code_Interface     {00} \
    CONFIG.Bar0_Type                {Memory} \
    CONFIG.Bar0_64bit               {false} \
    CONFIG.Bar0_Prefetchable        {false} \
    CONFIG.Bar0_Scale               {Megabytes} \
    CONFIG.Bar0_Size                {8} \
    CONFIG.Bar3_Enabled             {true} \
    CONFIG.Bar3_Type                {Memory} \
    CONFIG.Bar3_Scale               {Kilobytes} \
    CONFIG.Bar3_Size                {16} \
    CONFIG.MSIx_Enabled             {true} \
    CONFIG.MSIx_Table_Size          {4} \
    CONFIG.MSIx_Table_Offset        {00000300} \
    CONFIG.MSIx_Table_BIR           {BAR_0} \
    CONFIG.MSIx_PBA_Offset          {00002000} \
    CONFIG.MSIx_PBA_BIR             {BAR_3} \
] $ip

puts "=== AFTER ==="
puts "Device_Port_Type: [get_property CONFIG.Device_Port_Type $ip]"
puts "Vendor_ID: [get_property CONFIG.Vendor_ID $ip]"
puts "Device_ID: [get_property CONFIG.Device_ID $ip]"
puts "Subsystem_Vendor_ID: [get_property CONFIG.Subsystem_Vendor_ID $ip]"
puts "Subsystem_ID: [get_property CONFIG.Subsystem_ID $ip]"
puts "Class_Code_Base: [get_property CONFIG.Class_Code_Base $ip]"
puts "Class_Code_Sub: [get_property CONFIG.Class_Code_Sub $ip]"
puts "Bar0_Type/Scale/Size: [get_property CONFIG.Bar0_Type $ip] / [get_property CONFIG.Bar0_Scale $ip] / [get_property CONFIG.Bar0_Size $ip]"
puts "Bar3_Enabled/Type/Scale/Size: [get_property CONFIG.Bar3_Enabled $ip] / [get_property CONFIG.Bar3_Type $ip] / [get_property CONFIG.Bar3_Scale $ip] / [get_property CONFIG.Bar3_Size $ip]"
puts "MSIx_Enabled: [get_property CONFIG.MSIx_Enabled $ip]"
puts "MSIx_Table_Size: [get_property CONFIG.MSIx_Table_Size $ip]"
puts "MSIx_Table_Offset/BIR: [get_property CONFIG.MSIx_Table_Offset $ip] / [get_property CONFIG.MSIx_Table_BIR $ip]"
puts "MSIx_PBA_Offset/BIR: [get_property CONFIG.MSIx_PBA_Offset $ip] / [get_property CONFIG.MSIx_PBA_BIR $ip]"

generate_target {instantiation_template synthesis simulation} $ip
export_ip_user_files -of_objects $ip -force

puts "XCI_FILE: [get_property IP_FILE $ip]"
puts "DONE"
