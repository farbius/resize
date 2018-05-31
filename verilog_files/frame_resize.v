////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 25/05/18
// Design Name: frame_resize algorithm
////////////////////////////////////////////////////////////////////////////////


module frame_resize#(
parameter N_x      = 349,    //  amount of pixels in line
parameter N_y      = 349,    //  amount of lines  in frame
parameter resize   = 4,
parameter sign     = 1)		 //  '1' -- up resize, '0' -- down resize
	(
	input  clkNx,
    input  clk,
    input  rst,
// slave axi stream interface   
    input  s_axis_tvalid,
    input  s_axis_tuser,
    input  s_axis_tlast,
    input  [23 : 0] s_axis_tdata,
// master axi stream interface    
    output m_axis_tvalid,
    output m_axis_tuser,
    output m_axis_tlast,
    output [23 : 0] m_axis_tdata
    );
	
	reg [11 : 0] x_counter, y_counter;
	wire tvalid_new_x, tlast_new, tuser_new, tvalid_new_y;
	wire tvalid_new;
	wire tlast_strobe;
	reg  tlast_strobe_r;
	// DFF
	reg  s_axis_tvalid_r;
    reg  s_axis_tuser_r;
    reg  s_axis_tlast_r;
    reg  [23 : 0] s_axis_tdata_r;	
	
	/************up algorithm registers*********************/
	reg [ 3 : 0] counter_up;	
	reg [11 : 0]  addr_read, addr_write;
	
	reg [11 : 0] x_new_counter, y_new_counter;
	
	wire m_tvalid, clk_posedge;
	reg  clk_reg;
	
	wire up_tuser, up_tlast, up_tvalid;
	wire [23  : 0] up_tdata;
	
	reg  [1   : 0] mux_rd, mux_wr_reg;
	
	
	wire  [24-1 : 0] m_axis_tdata_1streg;
    wire  [24-1 : 0] m_axis_tdata_2ndreg;
    wire  [24-1 : 0] m_axis_tdata_3rdreg;
	wire  [24-1 : 0] m_axis_tdata_4threg;
	
	reg   [1    : 0] mux_wr;
	reg   [23   : 0] m_data;
	wire  a_wr_1st, a_wr_2nd, a_wr_3rd, a_wr_4th;
	wire  a_wr_5th, a_wr_6th, a_wr_7th, a_wr_8th;
	
	reg  frame_en;
	wire frame_done;
	
	assign frame_done = (y_new_counter == resize*N_y - 1 && x_new_counter == resize*N_x - 1 && m_tvalid) ? 1'b1 : 1'b0;
	
	assign up_tlast   = (y_new_counter == resize*N_y - 1)? 1'b1 : 1'b0;
	assign up_tuser   = (y_new_counter == 12'h000 && x_new_counter == 12'h000 && m_tvalid) ? 1'b1 : 1'b0;
	assign up_tvalid  =  m_tvalid;
	assign up_tdata   =  m_data;
 	
	/***************************************************/
	
	assign tvalid_new   = tvalid_new_x & tvalid_new_y;
	assign tvalid_new_x = (cnt_x == 0  && s_axis_tvalid_r && clk_posedge) ? 1'b1 : 1'b0;
	assign tvalid_new_y = (cnt_y == 0  && s_axis_tvalid_r && clk_posedge) ? 1'b1 : 1'b0;
	
	assign tlast_strobe = tlast_strobe_r; //(y_counter > N_y - resize)   ? 1'b1 : 1'b0;
	assign tlast_new    = tlast_strobe & tvalid_new;
	
	/*****************************************************/
	/********** output assignments ***********************/
	assign m_axis_tvalid      = (sign) ? up_tvalid : tvalid_new;
	assign m_axis_tlast       = (sign) ? up_tlast  : tlast_new;
	assign m_axis_tuser       = (sign) ? up_tuser  : (s_axis_tuser_r & clk_posedge);
	assign m_axis_tdata       = (sign) ? up_tdata  :  s_axis_tdata_r;

	/*****************************************************/
	/************* up resize algorithm *******************/
	
	always @(posedge clkNx) begin
            if(rst) begin
				frame_en <= 0;
			end else if (s_axis_tuser) begin
				frame_en <= 1;
			end else if (frame_done) begin
			    frame_en <= 0;
			end
	end // always
	
	
	
	
	assign clk_posedge = (clk == 1'b1 && clk_reg == 1'b0)? 1'b1: 1'b0;
	assign m_tvalid = (counter_up >= 4'h1 && counter_up <= resize && frame_en) ? 1'b1 : 1'b0;
	
	reg [2 : 0] repeat_line;
	
	always @(posedge clkNx)
				clk_reg <= clk;
				
	always @(posedge clkNx) begin
	
            if(rst || up_tuser) begin
					repeat_line <= 0;
						mux_rd  <= 0;					
            end else if(up_tlast) begin 
					if(repeat_line == resize - 1)begin
					repeat_line <= 0;
					    mux_rd  <= mux_rd + 1;
					end else begin 
					repeat_line <= repeat_line + 1; 
					end
			end
	end // clkNx
		
	
	always @(posedge clkNx) begin
	
			if(rst || s_axis_tuser) begin
				            counter_up <= 0;
				            addr_read  <= 0;
			end else begin
			
				if (mux_rd == mux_wr_reg) begin
					
					if(clk_posedge)begin					
								counter_up <= 0;								 
					end else begin				
							if(counter_up == resize + 1)begin							
								counter_up <= resize + 1;								  
							end else if (counter_up == resize - 1) begin						
							    counter_up <= counter_up + 1;								  								   
								 if(addr_read == N_y - 1) begin
											addr_read  <= 0;
								 end else begin
											addr_read  <= addr_read + 1;
								 end 								  								  
							end else begin							
								counter_up <= counter_up + 1;								  
							end
					end
				
				
				end // mux_rd == mux_wr
				 else begin 
				 
							if(counter_up == resize)begin							
								counter_up <= 1;								  
							end else if (counter_up == resize - 1) begin						
							    counter_up <= counter_up + 1;								  								   
								 if(addr_read == N_y - 1) begin
											addr_read  <= 0;
								 end else begin
											addr_read  <= addr_read + 1;
								 end 								  								  
							end else begin							
								counter_up <= counter_up + 1;								  
							end
				
				end // mux_rd != mux_wr
			
			
				
			
			end // synchr rst
	end			// clk
	
	/********************************************************/
	/************ pixel counting ****************************/	
	
	
		always @(posedge clkNx)begin
			if(rst)begin
						x_new_counter <= 0;
						y_new_counter <= 0;
			end else if(m_tvalid)begin
					 if(y_new_counter == resize*N_y - 1)begin
						y_new_counter <= 0;
							if(x_new_counter == resize*N_x - 1) begin
								x_new_counter <= 0;
							end else begin
								x_new_counter <= x_new_counter + 1;
							end
					 end else begin
						y_new_counter <= y_new_counter + 1;
					 end 		
			end	
		end // always
	
/***********************************************************/
	

	
	 // count of  lines  
    always @(posedge clk)
        if(rst || s_axis_tuser) mux_wr <= 0;
        else if(s_axis_tlast)   mux_wr <= mux_wr + 1;    

	always @(posedge clk)	
				mux_wr_reg	<= mux_wr;
        
     // always block
	 // generarte write addresses    

	 always @(posedge clk)
            if (rst)			                   addr_write <= 0; 	
            else if(s_axis_tvalid && s_axis_tlast) addr_write <= 0; 	
			else if(s_axis_tvalid)			       addr_write <= addr_write + 1;
			
		assign a_wr_1st   = (mux_wr == 2'b00 & s_axis_tvalid) ? 1'b1 : 1'b0;
		assign a_wr_2nd   = (mux_wr == 2'b01 & s_axis_tvalid) ? 1'b1 : 1'b0;
		assign a_wr_3rd   = (mux_wr == 2'b10 & s_axis_tvalid) ? 1'b1 : 1'b0;
		assign a_wr_4th   = (mux_wr == 2'b11 & s_axis_tvalid) ? 1'b1 : 1'b0;
		
	
	
		// buffers for keeping lines   
	   BRAM_Memory_24x24 #(12) i0 (.a_clk(clk), .a_wr(a_wr_1st), .a_addr(addr_write), .a_data_in(s_axis_tdata), .a_data_out(), 
	   .b_clk(clkNx), .b_wr(1'b0), .b_addr(addr_read), .b_data_in(), .b_data_out(m_axis_tdata_1streg), .b_data_en(1'b1));
	   
	   BRAM_Memory_24x24 #(12) i1 (.a_clk(clk), .a_wr(a_wr_2nd), .a_addr(addr_write), .a_data_in(s_axis_tdata), .a_data_out(), 
	   .b_clk(clkNx), .b_wr(1'b0), .b_addr(addr_read), .b_data_in(), .b_data_out(m_axis_tdata_2ndreg), .b_data_en(1'b1));
	   
	   BRAM_Memory_24x24 #(12) i2 (.a_clk(clk), .a_wr(a_wr_3rd), .a_addr(addr_write), .a_data_in(s_axis_tdata), .a_data_out(), 
	   .b_clk(clkNx), .b_wr(1'b0), .b_addr(addr_read), .b_data_in(), .b_data_out(m_axis_tdata_3rdreg), .b_data_en(1'b1));
	   
	   BRAM_Memory_24x24 #(12) i3 (.a_clk(clk), .a_wr(a_wr_4th), .a_addr(addr_write), .a_data_in(s_axis_tdata), .a_data_out(), 
	   .b_clk(clkNx), .b_wr(1'b0), .b_addr(addr_read), .b_data_in(), .b_data_out(m_axis_tdata_4threg), .b_data_en(1'b1));
	   
	   
	   
	   
	   
	always @(*) begin
		case (mux_rd)
			2'b00: begin
				m_data = m_axis_tdata_1streg;
			end
			
			2'b01: begin
			    m_data = m_axis_tdata_2ndreg;
			end
			
			2'b10: begin
			    m_data = m_axis_tdata_3rdreg;
			end
			
			2'b11 : begin
			    m_data = m_axis_tdata_4threg;
			end
			
			default: begin
			    m_data = m_axis_tdata_4threg;
			end
		endcase
	end	
	   
						
	/******************************************************/
	/************** down resize algorithm     ************/
	

	reg [3 : 0] cnt_x;
	always @(posedge clk) begin
			if(rst) begin
				       cnt_x <= 0;
			end else if(s_axis_tvalid_r) begin
				if (cnt_x == resize - 1) begin 
					cnt_x <= 0;
				end else begin
					cnt_x <= cnt_x + 1;
			    end			
			end		
	end

	//    D-FF (1 clock latency)	
	always @(posedge clk) begin
		  s_axis_tvalid_r <= s_axis_tvalid;
		  s_axis_tuser_r  <= s_axis_tuser;
		  s_axis_tlast_r  <= s_axis_tlast;
          s_axis_tdata_r  <= s_axis_tdata;
		  
		  if(y_counter > N_y - resize)
			tlast_strobe_r	<= 1'b1;
		  else
			tlast_strobe_r	<= 1'b0;

	end
	
	reg [3 : 0] cnt_y;
	always @(posedge clk) begin
			if(rst) begin
				       cnt_y <= 0;
			end else if(s_axis_tlast_r) begin
				if (cnt_y == resize - 1) begin 
					cnt_y <= 0;
				end else begin
					cnt_y <= cnt_y + 1;
			    end			
			end		
	end
	
	
/***********************************************************/
/************ pixel counting ****************************/	
	always @(posedge clk)begin
		if(rst)begin
					x_counter <= 0;
					y_counter <= 0;
		end else if(s_axis_tvalid)begin
				 if(s_axis_tlast)begin
					y_counter <= 0;
					x_counter <= x_counter + 1;					
				 end else if(s_axis_tuser) begin
				    x_counter <= 0;
				    y_counter <= y_counter + 1;
				 end else begin
					y_counter <= y_counter + 1;
				 end 		
		end	
	end // always
	
/***********************************************************/
	
	 
	 // piplined axi stream interface
	 // 
	// assign m_axis_tvalid      = tvalid_new;
	// assign m_axis_tlast       = tlast_new;
	// assign m_axis_tuser       = s_axis_tuser_r;
	// assign m_axis_tdata       = s_axis_tdata_r;
	
	
	
	
	
	
	
	
	
endmodule
