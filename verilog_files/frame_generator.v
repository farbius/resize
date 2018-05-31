`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 14/05/18
// Design Name: gamma_correction
////////////////////////////////////////////////////////////////////////////////

module frame_generator #(
parameter Nrows = 349,  // N_y
parameter Ncol  = 349)  // N_x parameter for size of picture
(
input   clk,
input   rst,
output  SOF, 
output  EOL,
output DVAL,
output  read_done,
output [23 : 0] pixel
    );
    
    function integer clogb2 (input integer depth);
     begin
         depth = depth -1;
        for(clogb2 = 0; depth > 0;clogb2 = clogb2 + 1)begin
         depth = depth >> 1;
        end
     end
     endfunction
	 
	 function integer multply (input integer row, input integer column);
     begin
         multply = row * 3 * column;       
     end
     endfunction
     
  
	localparam N     = multply(Nrows, Ncol);
	localparam Naddr = clogb2(N);
    
    reg  [7:0] Rdata [0 : N -1];
    reg  [7:0] Gdata [0 : N -1];
    reg  [7:0] Bdata [0 : N -1];
    
     reg  [7:0] Rdata_reg;
     reg  [7:0] Gdata_reg;
     reg  [7:0] Bdata_reg;
     
     // address  
     reg [2**Naddr - 1 : 0] address, address_reg, add_reg;
	 reg data_valid, data_valid_reg;
	 reg data_last;
	 reg [24 - 1 : 0] row;
	 reg [24 - 1 : 0] column;
	 
	 reg [23 : 0] test_data;
	 	     
    assign pixel     = {Rdata_reg, Gdata_reg, Bdata_reg};
    assign read_done = (add_reg == N)?1'b1 : 1'b0;
	assign SOF       = (row == 24'd1 && column == 24'd0 && add_reg <= Nrows*Ncol)?1'b1 : 1'b0;
	assign EOL       = (row == Nrows && add_reg <= Nrows*Ncol)?1'b1 : 1'b0;
	assign DVAL      = (data_valid && !data_valid_reg && add_reg <= Nrows*Ncol) ? 1'b1 : 1'b0;
    
    initial $readmemh("Rdata.txt", Rdata, 0, N -1);
    initial $readmemh("Gdata.txt", Gdata, 0, N -1);
    initial $readmemh("Bdata.txt", Bdata, 0, N -1);

    
   always @(posedge clk)begin    
    if(rst)begin
        address    <= 0;
		data_valid <= 0;
		row        <= 0;
		column     <= 0;  
        test_data  <= 0;	
		add_reg    <= 0;
		data_valid_reg <=0 ;
    end else begin
	
		if(row == Nrows)begin
		    row <= 1;
				   if(column == Ncol - 1) begin 
						column <= 0;
					   address <= 0;
					   data_valid_reg <= !(data_valid_reg);
                   end else begin 
						column <= column + 1;
					   address <= address + 1;
				   end	
		end else begin
		         row   <= row + 1;
		    address    <= address + 1;
			data_valid <= 1;
		end
		
		test_data   <= test_data + 1;
		address_reg <= address;
		
		 add_reg    <= add_reg + 1;
	end
   end // always
    
 // read example from memory   
   always @(posedge clk)
        if(rst)
         Rdata_reg <= 0;
        else
         Rdata_reg <= Rdata[add_reg];
         
   always @(posedge clk) 
        if(rst)
         Gdata_reg <= 0;
        else    
         Gdata_reg <= Gdata[add_reg];
    
   always @(posedge clk) 
        if(rst)
         Bdata_reg <= 0;
        else
         Bdata_reg <= Bdata[add_reg];
      
    
    
endmodule