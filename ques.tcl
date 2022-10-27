###########################################################################
# The below TCL script simulates a network topology in a ns-2 simulator:
# 
# 1. There are nodes from n0 to n7.
# 2. All links are duplex with 2ms delay and DropTail queue.
# 3. 1Mb bandwidth between n0-n2, n1-n2, n4-n3, n5-n6, n5-n7
# 4. 700kb bandwidth between n2-n3, n3-n5
# 5. 3 data sources. 2 UDP sources and 1 TCP.
# 6. UDP Sources:
#    a. Application Traffic - CBR
#    b. Packet Size = 500 Bytes
#    c. Interval = 0.005 Sec
#    d. Start at 8 Sec
#    e. End at 13 Sec
# 7. TCP Source:
#    a. Application Traffic - FTP
#    b. Start at 1 Sec
#    c. End at 19 Sec
# 8. Different colors for different traffic flows
# 9. NAM and Trace enabled
# 10. Enable Script for both TCP Reno and TCP Cubic variants.
#
# Functions added:
#  - plotWindow
#    - This function generates a congestion graph.
#    - This is done for both TCP Reno and TCP Cubic variants.
#    - Generated for every 0.2 second interval.
# 
# Scripts added:
#  - packet dropped count for TCP Reno and TCP Cubic variants.
# ########################################################################

#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

#Open the NAM trace file
#Uncomment below line for TCP Reno Simulation
set nf [open outReno.nam w]
#Uncomment below line for TCP Cubic Simulation
#set nf [open outCubic.nam w]
$ns namtrace-all $nf
#Uncomment below line for TCP Cubic
#set tf [open TCPCubic.tr w]
#Uncomment below line for TCP Reno
set tf [open TCPReno.tr w]
$ns trace-all $tf

#Set session routing policy for all nodes
$ns rtproto Session

#Procedure to plot the congestion window
proc plotWindow {tcpSource outfile} {
  global ns
  set now [$ns now]
  set cwnd [$tcpSource set cwnd_]

#the data is recorded in a file called congestionReno1.xg for TCP Reno
#the date is recorded in a file called congestionCubic1.xg for TCP Cubic
  puts $outfile "$now $cwnd"
  $ns at [expr $now + 0.2] "plotWindow $tcpSource $outfile"
}

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Close the trace file
        close $tf
        #Uncomment below line for TCP Reno
        exec nam outReno.nam &
        #Uncomment below line for TCP Cubic
        #exec nam outCubic.nam &
        #Uncomment below line for opening xgraph for TCP Reno
        exec xgraph congestionReno.xg -geometry 300x300 &
        #Uncomment below line for opening xgraph for TCP Cubic
        #exec xgraph congestionCubic.xg -geometry 300x300 &
        exit 0
}

#Create nine nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]
set n8 [$ns node]
set n9 [$ns node]

#Create links between the nodes
$ns duplex-link $n1 $n2 2Mb 20ms DropTail
$ns duplex-link $n9 $n2 1.5Mb 20ms DropTail
$ns duplex-link $n5 $n2 2Mb 20ms DropTail
$ns duplex-link $n2 $n3 1.5Mb 30ms DropTail
$ns duplex-link $n3 $n6 2Mb 20ms DropTail
$ns duplex-link $n3 $n4 1.5Mb 30ms DropTail
$ns duplex-link $n4 $n7 2Mb 20ms DropTail
$ns duplex-link $n4 $n8 2Mb 20ms DropTail


#Set Queue Size for links to 10
#$ns duplex-link $n1 $n7 10
#$ns duplex-link $n1 $n6 10
#$ns duplex-link $n9 $n6 10
#$ns duplex-link $n5 $n8 10


#Give node position (for NAM)
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n9 $n2 orient right
$ns duplex-link-op $n5 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right 
$ns duplex-link-op $n3 $n6 orient right-down
$ns duplex-link-op $n3 $n4 orient right
$ns duplex-link-op $n4 $n7 orient right-up
$ns duplex-link-op $n4 $n8 orient right-down

#Create a UDP agent and attach it to node n5
set udp5 [new Agent/UDP]
$udp5 set fid_ 1
$ns attach-agent $n5 $udp5

#Create a CBR traffic source and attach to udp5
set cbr5 [new Application/Traffic/CBR]
$cbr5 set packetSize_ 500
$cbr5 set interval_ 0.005
$cbr5 attach-agent $udp5

#Create a UDP agent and attach it to node n8
set udp8 [new Agent/UDP]
$udp8 set fid_ 3
$ns attach-agent $n8 $udp8

#Create a CBR traffic source and attach to udp8
set cbr8 [new Application/Traffic/CBR]
$cbr8 set packetSize_ 500
$cbr8 set interval_ 0.005
$cbr8 attach-agent $udp5

#Create a TCP agent and attach it to node n1
#uncomment below line when running for TCP Cubic
#set tcp1 [new Agent/TCP/Linux]
#uncomment below line when running for TCP Reno
set tcp1 [new Agent/TCP/Reno]
$tcp1 set class_ 2
$tcp1 set fid_ 2
#uncomment below line when running for TCP Cubic
#$ns at 0 "$tcp1 select_ca cubic"
$ns attach-agent $n1 $tcp1

#Create a FTP traffic source and attach to tcp1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1  

#Create the sink for TCP1
set sink6 [new Agent/TCPSink]
$ns attach-agent $n6  $sink6
$ns connect $tcp1 $sink6

#Create the sink for UDP5
set null70 [new Agent/Null]
$ns attach-agent $n7 $null70
$ns connect $udp5 $null70

#Create the sink for UPD1
set null71 [new Agent/Null]
$ns attach-agent $n7 $null71
$ns connect $udp5 $null71

#Schedule events for the CBR and FTP agents
$ns at 8.0 "$cbr5 start"
$ns at 8.0 "$cbr8 start"
$ns at 1.0 "$ftp1 start"
$ns at 19.0 "$ftp1 stop"
$ns at 13.0 "$cbr5 stop"
$ns at 13.0 "$cbr8 stop"

#Detach tcp and sink agents (not really necessary)
$ns at 19.0 "$ns detach-agent $n1 $tcp1 ; $ns detach-agent $n6 $sink6"

#Call the finish procedure after 20 seconds of simulation time
$ns at 20.0 "finish"

#Print CBR packet size and interval
puts "CBR packet size for n5 = [$cbr5 set packet_size_]"
puts "CBR interval n5 = [$cbr5 set interval_]"

puts "CBR packet size for n8 = [$cbr8 set packet_size_]"
puts "CBR interval n8 = [$cbr8 set interval_]"

#Uncomment below line to Generate graph for TCP Reno congestion
set outfile [open "congestionReno1.xg" w]
#Uncomment below line to Generate graph for TCP Cubic congestion
#set outfile [open "congestionCubic1.xg" w]
$ns at 0.0 "plotWindow $tcp1 $outfile"

#Run the simulation
$ns run

#########################################################################
# The below script does the following:
# 1. Opens the trace file generated for a TCP Variant (Reno/Cubic)
# 2. Analyzes each line for "Drop" event and TCP Packet Type.
# 3. Counts the dropped packets.
# 4. Prints the value.
########################################################################
#Uncomment below line for TCP Reno
#set fid [open TCPReno.tr]
#Uncomment below line for TCP Cubic
#set fid [open TCPCubic.tr]
#set trace [read $fid]
#close $fid
#
## Split into records on newlines
#set records [split $trace "\n"]
#
#set packtdropped 0
#
##Iterate over the records
#foreach rec $records {
#
#     # Split the records to fields with space as separator
#     set fields [split $rec " "]
#    
#     # Assign fields to variables and count the dropped packets for tcp
#     lassign $fields \
#       event time fnode tnode pkttyp psize flags fid saddr daddr snum pid
#
#       if { $pkttyp == "tcp" && $event == "d"
#       } then {
#          incr packtdropped 
#       }
#}
#puts "Total packets dropped for TCP Cubic is: $packtdropped"


