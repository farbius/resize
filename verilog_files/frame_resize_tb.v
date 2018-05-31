`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 25/05/18
// Design Name: frame_resize_tb
////////////////////////////////////////////////////////////////////////////////
`include "parameters.vh"

module frame_resize_tb( );

	reg clkNx;
    reg clk;
    reg rst;
// slave axi stream interface   
    wire s_axis_tvalid;
    wire s_axis_tuser;
    wire s_axis_tlast;
    wire [23 : 0] s_axis_tdata;
// master axi stream interface    
    wire m_axis_tvalid;
    wire m_axis_tuser;
    wire m_axis_tlast;
	reg  read_done_r, read_done_rr;
    wire [23 : 0] m_axis_tdata;
    wire read_done;
    `define PERIOD 5     // 100 MHz clock 
	
	function integer multply (input integer row, input integer column);
     begin
        if(sign)
         multply = row * column* d_scaling * d_scaling; 
        else
         multply = (row/d_scaling + 0)* (column/d_scaling + 0);      
     end
     endfunction
     
	localparam N     = multply(N_y, N_x);
		
	

	initial begin
    clk       <= 0;                              
    forever #(`PERIOD*16)  clk  =  ! clk; 
    end
	
	initial begin
    clkNx       <= 0;                              
    forever #(`PERIOD)    clkNx =  ! clkNx; 
    end
		
	 
	event reset_trigger;
    event reset_done_trigger; 


   frame_generator #(N_y, N_x) dutA (.clk(clk), .rst(rst), .SOF(s_axis_tuser), .EOL(s_axis_tlast), .DVAL(s_axis_tvalid), .read_done(read_done), .pixel(s_axis_tdata)); 
  
   frame_resize    #(N_x, N_y, d_scaling, sign)dutB (.clkNx(clkNx), .clk(clk),.rst(rst),.s_axis_tvalid(s_axis_tvalid),.s_axis_tuser(s_axis_tuser),.s_axis_tlast(s_axis_tlast),.s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),.m_axis_tuser(m_axis_tuser),.m_axis_tlast(m_axis_tlast),.m_axis_tdata(m_axis_tdata));    

    integer fidR, fidG, fidB;
  
    initial begin 
     rst       <= 1;
         @ (reset_trigger); 
         @ (posedge clk) rst <= 1;             
         repeat (20) begin
         @ (posedge clk); 
         end 
         rst = 0;
          -> reset_done_trigger;
    end 
    
    reg [23 : 0] data_counter;
    wire   rd_done;
    assign rd_done = (data_counter == N - 1)? 1'b1: 1'b0;
	
	reg [63 : 0] shift_register;
	wire rd_done_wire;
	
	always @(posedge clkNx)
		if (rst) shift_register <= 0;
		else     shift_register <= {shift_register[62 : 0], rd_done};
		
	assign rd_done_wire = shift_register[63];
	
	
	always @(posedge clkNx)
		if(rst) 				data_counter <= 0;
		else if (m_axis_tvalid) data_counter <= data_counter + 1;
		
	
	
	initial  begin    
     fidR = $fopen("Rs_out.txt","w");
     fidG = $fopen("Gs_out.txt","w");
     fidB = $fopen("Bs_out.txt","w");

          -> reset_trigger;
          @(reset_done_trigger);  
			   
		while(!rd_done_wire )begin
				if(m_axis_tvalid)begin
					  $fwrite(fidR, "%d \n", m_axis_tdata[23 : 16]);
					  $fwrite(fidG, "%d \n", m_axis_tdata[15 : 8]);
					  $fwrite(fidB, "%d \n", m_axis_tdata[7  : 0]);
					  @ (posedge clkNx); 		
				end else begin
					  @ (posedge clkNx);
				end		  
		end	
		  $fclose(fidR);
		  $fclose(fidG);
		  $fclose(fidB); 
		  
	       
      #5000 $stop;                                                
    end                
  
endmodule
