	
#!/bin/bash
	
	
#--------------------VARIABLE DECLARATION--------------------#
	
	declare -a INPUT_PORT_ARRAY
	declare -a OUTPUT_PORT_ARRAY
	declare -a CONSTRAINT
	declare OPTION
	declare MAIN_MENU_CHOICE
	declare MAIN_LOOP_CONTINUE
	declare CONSTRAINT_CONTINUE
	declare CONSTRAINT_COUNT=1
	declare i=0
	declare j=0
	declare -a arr2  
	declare -a arr3
	
	
#-------------------------------------------------------------#
	
#----------------------FIND THE FILE--------------------------#
	
#-------------------------------------------------------------#
	
#------------------COMPILATION OF VERILOG FILE----------------#

Compile(){
	iverilog $1 2> c
	size=$(ls -l c | cut -d " " -f5)
	
	if [[ ! $size -eq 0 ]];then
		cat c
		rm c
		echo "Press y to goto Main Menu else n to exit"
		read -r ch
		if [[ $ch == y ]];then
			Main_Menu $1

		else
			exit 1
		fi
	
	else
		echo "File Successfully compiled"
		Main_Menu $1
	fi
}
#-------------------------------------------------------------#
	
	
#--------------------FETCHING THE MODULE NAME-----------------#

Fetching_Signals(){

	mod1=$(egrep -o '\<module\> *([a-Z0=9]+)' $1 | sed 's/module *//g')
	
#----------------------------------------------------------------#
	
	sed -r ':x;${s/\n/ /g};N;bx'  $1  | sed -r -e   's/\(//g' -e 's/\)//g'  | sed  -r  -e  's/(.);/\1 ;/g'    -e 's/(\]) *([a-Z]*)/\1\2/g' -e  's/ *, */,/g' -e 's/reg//g' -e 's/logic//g' -e 's/wire//g' -e 's/\[ *([0-9]+) *: *([0-9]+) *\]/\[\1\:\2\]/g'  >  temp_file2
	
	
#.........../////..feching the input port..////...............#
	
	
	fil=$(sed -r 's/ *input/\n input/g' temp_file2  | sed -r 's/(\[[0-9]:[0-9]\])([a-Z]+),([a-Z]+)/\1\2,\1\3/g')
	
	IFS=$' \n ,'
	p=0
	k=0
	for i in $ $fil;do
	
	        if [[ $i =~ input  ]];then
	                p=1
	                continue
	
	        fi
	
	        if [[ $i =~  output ]] || [[ $i =~ ';' ]] ;then
	                p=0
	                continue
	
	        elif [[ p -eq 1 ]];then
	
	                arr2[k++]=$i
	
	
	        fi
	done
	
	z=0
	for i in "${arr2[@]}";do
	        if [[ $i =~ [[:graph:]]  ]];then
	                i11=$(echo $i | sed -r 's/[[:space:]]//g')
	                INPUT_PORT_ARRAY[z++]=$i11
	
	                #............store clock and reset.and enable/valid port.................
	
	                if [[ $i11 =~ (clk|clock|CLOCK|CLK|Clk|Clock)[a-Z0-9_]* ]] ;then
	
	                        c=$i11
	                fi
	
	                if [[ $i11 =~ (rst|reset|RST|RESET|Reset|Rst)[a-Z0-9_]* ]] ;then
	
	                        rt=$i11
	                fi
	
	                if [[ $i11 =~ (valid|enable|VALID|ENABLE|Valid|Enable)[a-Z0-9_]* ]]  || [[ $i11 =~ (EN|En|en)[0-9]* ]];then
	
	                        en=$i11
	                fi
	
	        fi
	done

#.............///////////end of fetching input port///....................
	
	
#............//////////fetching the output port/////////...............
	
	fil1=$(sed -r 's/ *output/\n output/g' temp_file2  |  sed -r 's/(\[[0-9]:[0-9]\])([a-Z]+),([a-Z]+)/\1\2,\1\3/g')
	IFS=$' \n ,'
	q=0
	l=0
	for i in $fil1 ;do
	        if [[ $i =~ output  ]];then
	                q=1
	                continue
	        fi
	
	        if [[ $i =~  input ]] || [[ $i =~ ';' ]] ;then
	                q=0
	                continue
	
	        elif [[ q -eq 1 ]];then
	                arr3[l++]=$i
	
	        fi
	done
	
#..............//remove leading and triling edge and null element of array//////............
	
	y=0
	for i in "${arr3[@]}";do
	        if [[ $i =~ [[:graph:]]  ]];then
	                i12=$(echo $i | sed -r 's/[[:space:]]//g')
	                OUTPUT_PORT_ARRAY[y++]=$i12
	        fi
	done
	
}

#--------------------CREATING CLASS TRANSACTION--------------------#

Transaction_Class(){

#....CHECK FILE EXIST OR NOT.............
	
	if test -f "transaction.sv";then
		rm transaction.sv
	fi
	
#........................................
	
	echo "class transaction;" >> transaction.sv
	echo " //declaring the transaction items" >> transaction.sv
	
	for i in "${INPUT_PORT_ARRAY[@]}";do
	
		if [[ $i == $c  ]] || [[ $i == $rt ]]  || [[ $i == $en  ]];then
			continue
		else
			echo "   rand bit $i;" >> transaction.sv
		fi
	done
	
	for i in "${OUTPUT_PORT_ARRAY[@]}";do
		echo "   bit $i;" >> transaction.sv
	done
	
	
#............................ADDING CONSTRAINTS..........................
	
	echo "Enter y to add constraints else n"
	read -r OPTION
	
	if [[ $OPTION = 'y' ]]; then
		FUNCTIONALITY["CONSTRAINT"]=1
		echo "You have following variables"
	
		for i in ${!INPUT_PORT_ARRAY[@]};do
			let j=$j+1
			echo "$j:-  ${INPUT_PORT_ARRAY[$i]}"
		done
	        
		CONSTRAINT_CONTINUE=""        
		until [[ $CONSTRAINT_CONTINUE == "n" ]]
		do 
			echo "Enter constraint"
			read -r CONSTRAINT[$CONSTRAINT_COUNT]
			let CONSTRAINT_COUNT=CONSTRAINT_COUNT+1
			echo "continue?(y/n)"
			read -r CONSTRAINT_CONTINUE
		done
	
		if [[ ${FUNCTIONALITY["CONSTRAINT"]} -eq 1 ]];then
		for i in ${!CONSTRAINT[@]};do
			printf "constraint cons$i{ ${CONSTRAINT[$i]}; }\n" >>  transaction.sv
		done
		fi
	fi
	
#........................................................................
	
	cat<<EOT >>transaction.sv
	function void display(string name);
	    \$display("-------------------------");
	    \$display("- %s ",name);
	    \$display("-------------------------");
EOT
	
	for i in "${INPUT_PORT_ARRAY[@]}";do
	
		if [[ $i == $c  ]] || [[ $i == $rt ]]  || [[ $i == $en  ]];then
			continue
		else
			gg=$(echo $i | sed -r 's/\[.*\](.*)/\1/g')
			echo  "   	    \$display(\"- $gg = %0d\",$gg);" >> transaction.sv
		fi
	
	
	done
	
	for i in "${OUTPUT_PORT_ARRAY[@]}";do
		gg1=$(echo $i | sed -r 's/\[.*\](.*)/\1/g')
		echo  "   	    \$display(\"- $gg1 = %0d\",$gg1);" >> transaction.sv
	done
	
	cat<<EOT >>transaction.sv
	    \$display("-------------------------");
	  endfunction
	endclass
EOT

	cat transaction.sv
	echo ""
}

#--------------------------END 0F TRANSACTION CLASS-------------------------#	


#----------------------CREATING OF GENARATOR CLASS---------------------------#
Generator_Class(){

	cat<<EOT >>generator.sv
	class generator;
	  rand transaction trans;
	  //repeat count, to specify number of items to generate
	  int  repeat_count;
	  mailbox gen2driv;
	  //event, to indicate the end of transaction generation
	  event ended;
	  //constructor
	  function new(mailbox gen2driv); 
	    this.gen2driv = gen2driv;
	  endfunction
	  //main task, generates(create and randomizes) the repeat_count number of transaction packets and puts into mailbox
	  task main();
	    repeat(repeat_count) begin
	    trans = new();
	    if( !trans.randomize() ) \$fatal("Gen:: trans randomization failed");
	      trans.display("[ Generator ]");
	      gen2driv.put(trans);
	    end
	    -> ended; //triggering indicatesthe end of generation
	  endtask
	endclass
EOT
	
	cat generator.sv
}

#------------------------END OF GENERATOR CLASS---------------------------------#
	
	
#------------------------CREATING OF INTERFACE----------------------------------#

Interface(){

#...........CHECK FILE EXIST OR NOT.............
	
	if test -f "interface.sv";then
		rm interface.sv
	fi
	
#...............................................
	
	
	echo "	interface intf(input logic $c,$rt);" >> interface.sv
	
	echo   "	//declaring the signals" >>interface.sv
	
	[[ ! -z $en  ]] && echo "	logic $en" >> interface.sv
	
		for i in "${INPUT_PORT_ARRAY[@]}";do
			if [[ $i == $c  ]] || [[ $i == $rt ]]  || [[ $i == $en  ]];then
				continue
			else
				echo  "	logic $i;" >> interface.sv
			fi
		done
	
	
#............INSERTING CLOCKING BLOCK AND MODPORT...............
	
	
	cat <<EOT >> interface.sv
	clocking driver_cb(posedge $c);
		default input #1 output #1;
EOT
	
	
	for i in ${INPUT_PORT_ARRAY[@]}; do
		if [[ ! $i == $c || $i == $rt  ]]; then
		echo "		output	`echo $i | sed 's/\[.*\]//'`;" >> interface.sv
	fi
	done
	
	
	for i in ${OUTPUT_PORT_ARRAY[@]};do
		echo "		input	`echo $i | sed 's/\[.*\]//'`;" >> interface.sv
	done
	
	cat <<EOT >> interface.sv
	endclocking
	modport DRIVER(clocking Driver_cb, input $c, $rt);
	endinterface
EOT

	cat interface.sv
}

#---------------------------END OF INTERFACE----------------------------#
	
#-----------------------CREATING DRIVER CLASS---------------------------#

Driver_Class(){
	cat << EOT > driver.sv
	\`define DRIV_IF vif.DRIVER.driver_cb
	class driver;
		
		transaction tr;
		mailbox gen2driv;
		virtual intf vif;
		int transactions;
		function new(mailbox gen2driv, virtual intf vif);
			this.gen2driv = gen2driv;
			this.vif = vif;
		endfunction
		
		task reset;	
			wait(vif.DRIVER.$c); 
			\$display("Driver reset started");
EOT
	
#................MAKING DRIVER RESET AND MAIN..................
	
	IFS=$'\n'
	for i in ${INPUT_PORT_ARRAY[@]}; do  
		if [[  $i == $c ]]  ||  [[  $i == $rt ]];then 
			continue
		else
			echo "			`echo $i | sed 's/\[.*\]//'` <= 0;" >> driver.sv
		fi
	done
	
	cat << EOT >> driver.sv
			\$display("Driver reset ended");
			wait(! vif.DRIVER.$rt);
		endtask
		
		task main;
			forever begin
				gen2driv.get(tr);
				@(posedge vif.DRIVER.$c);
EOT
	
#....................DRIVING INPUT SIGNALS......................
	
	for i in ${INPUT_PORT_ARRAY[@]};do
		i=`echo $i |  sed  's/\[.*\]//'`
		if [[ ! $i == $c ]] || [[ $i == $rt ]]; then
			[[ ! $i == $en ]] && echo "				\`DRIV_IF.$i <= tr.$i;" >> driver.sv || echo "				\`DRIV_IF.$i <= tr.$i;" >> driver.sv
		fi
	done
	
#...............................................................
	
	
#...................DRIVING OUTPUT SIGNALS......................
	
	cat << EOT >> driver.sv
				@(posedge vif.DRIVER.$c);
EOT
	
	for i in ${OUTPUT_PORT_ARRAY[@]};do
		i=`echo $i | sed 's/\[.*\]//'`
		echo "				tr.$i = \`DRIV_IF.$i" >> driver.sv
	done
	
#..............................................................
	
	
	cat << EOT >> driver.sv
				@(posedge vif.DRIVER.$c);
				tr.display("[ Driver ]");
				transactions++;
			end
		endtask
	endclass
EOT

	cat driver.sv
}

#-------------------------------------END OF DRIVER-------------------------------------#
	
	
#------------------------CREATING ENVIRONMENT CLASS-------------------------------------#

Environment_Class(){

#...........CHECK FILE EXIST OR NOT.............
	
	if test -f "environment.sv";then
		rm environment.sv
	fi
	
#...............................................
	
	cat<<EOT >>environment.sv
	\`include "transaction.sv"
	\`include "generator.sv"
	\`include "driver.sv"
	class environment;
	  //generator and driver instance
	  generator gen;
	  driver    driv;
	  //mailbox handle's
	  mailbox gen2driv;
	  //virtual interface
	  virtual intf vif;
	  //constructor
	  function new(virtual intf vif);
	    //get the interface from test
	    this.vif = vif;
	    //creating the mailbox (Same handle will be shared across generator and driver)
	    gen2driv = new();
	    //creating generator and driver
	    gen  = new(gen2driv);
	    driv = new(vif,gen2driv);
	  endfunction
	  //
	  task pre_test();
	    driv.reset();
	  endtask
	  taskwait(gen.repeat_count == driv.no_transactions);
	  endtask
	  //run task
	  task run;
	    pre_test();
	    test();
	    post_test();
	    \$finish;
	  endtask
	endclass test();
	    fork
	    gen.main();
	    driv.main();
	    join_any
	  endtask
	  task post_test();
		wait(gen.ended.triggered);
		wait(mon.repeat_count == gen.repeat_count);
	   endtask
		task run;
			pre_test;
			test;   
			post_test;
			\$finish;
		endtask
	endclass
EOT

	cat environment.sv
}

#---------------------------END OF ENVIRONMENT CLASS-----------------------------#
	
	
	
#-------------------------------CREATING RANDOM TEST-----------------------------#

Random_Test(){
#..........CHECK FILE EXIST OR NOT.............
	
	if test -f "randam_test.sv";then
		rm randam_test.sv
	fi
	
#.............................................
	
	
	cat << EOT > random_test.sv
	\`include "environment.sv"
	program test(intf in);
		environment env;
		initial begin
			env = new(in);
			env.gen.repeat_count = 5;
			env.mon.repeat_count = 0;
			env.run;
		end
	endprogram
EOT

	cat random_test.sv
}
#-----------------------------END OF RANDAM TEST--------------------------------#
	
	
#------------------------CREATING TOP_TESTBENCH--------------------------------#
	
Testbench_Top(){	
#...........CHECK FILE EXIST OR NOT.............
	
	if test -f "top_test_bench.sv";then
	        rm top_test_bench.sv
	fi
	
#...............................................
	
	
	cat <<EOT >>top_test_bench.sv
	//including interfcae and testcase files
	\`include "interface.sv"
	\`include "random_test.sv"
	 module testbench_top;
	  //clock and reset signal declaration
	  bit $c;
	  bit $rt;
	  //clock generation
	  always #5 $c = ~$c;
	  //reset Generation
	  initial begin
	    $rt = 1;
	    #5 $rt =0;
	  end
	  //creatinng instance of interface, inorder to connect DUT and testcase
	  intf i_intf($c,$rt);
	  //Testcase instance, interface handle is passed to test as an argument
	  test t1(i_intf);
EOT
	
	
	
	echo  "	DUT $mod1 (" >>top_test_bench.sv
	
	for i in "${INPUT_PORT_ARRAY[@]}";do
	        g=$(echo $i | sed -r 's/\[.*\](.*)/\1/g')
	        echo "	.$g(i_intf.$g)," >> top_test_bench.sv
	done
	
	
	g11=$(echo "${#OUTPUT_PORT_ARRAY[*]}")
	
	for i in "${OUTPUT_PORT_ARRAY[@]}";do
	        g1=$(echo $i | sed -r 's/\[.*\](.*)/\1/g')
	        g11=$g11-1
	        echo -n  "	.$g1(i_intf.$g1)" >> top_test_bench.sv
	        
		if [[ $g11 -gt 0 ]];then
	                echo "," >> top_test_bench.sv
	        fi
	done
	
	echo  " );" >> top_test_bench.sv
	
	
	cat<<EOT>>top_test_bench.sv
	 //enabling the wave dump
	  initial begin 
	    \$dumpfile("dump.vcd"); \$dumpvars;
	  end
	endmodule 
EOT

	cat top_test_bench.sv
}

#---------------------------------CREATING  TOP_TESTBENCH----------------------------#

Main_Menu(){
	echo -e "1. Select the directory.\n"
	echo -e "2. Compile the verilog file.\n"
	echo -e "3. Transaction Class.\n"
	echo -e "4. Generator Class.\n"
	echo -e "5. Driver Class.\n"
	echo -e "6. Interface.\n"
	echo -e "7. Environment Class.\n"
	echo -e "8. Random Test.\n"
	echo -e "9. Testbench top module.\n"	
	echo -e "10. Generate complete testbench.\n"
	echo -e "11. Exit\n"
	
	#.....Taking User's Choice....
	echo -e "Enter Choice"
	read -r MAIN_MENU_CHOICE
	
	if [[ $MAIN_MENU_CHOICE -lt 11 ]] && [[ $MAIN_MENU_CHOICE -gt 2 ]];then
		Fetching_Signals $1
	fi

	case $MAIN_MENU_CHOICE in
		1)
			echo "1"
			;;

		2)
			Compile $1
			;;

		3)
			Transaction_Class 
			;;

		4) 
			Generator_Class 
			;;
		
		5)	
			Driver_Class 
			;;

		6)
			Interface 
			;;

		7)
			Environment_Class
			;;

		8) 
			Random_Test
			;;

		9)
			Testbench_Top
			;;

		10)
			echo -e "\n..............TRANSACTION CLASS.............."
			Transaction_Class 
			
			echo -e "\n..............GENERATOR CLASS..................."
			Generator_Class 
			
			echo -e "\n..............DRIVER CLASS....................."
			Driver_Class 
			
			echo -e "\n..............INTERFACE........................"
			Interface 
			
			echo -e "\n..............ENVIRONMENT CLASS................"
			Environment_Class 
			
			echo -e "\n..............RANDOM TEST....................."
			Random_Test 
			
			echo -e "\n..............TESTBENCH TOP MODULE................"
			Testbench_Top 
			;;

		11)
			exit 1
			;;

		*)
			echo -e "Enter choice between 1 and 11\n"
			Main_Menu $1
			;;
		esac

}

while :
do
	Main_Menu $1
done
