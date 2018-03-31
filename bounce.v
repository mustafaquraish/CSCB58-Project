// Part 2 skeleton

module bounce
    (
        CLOCK_50,						//	On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
		  LEDR,
          LEDG,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,   						//	VGA Clock
        VGA_HS,							//	VGA H_SYNC
        VGA_VS,							//	VGA V_SYNC
        VGA_BLANK_N,					//	VGA BLANK
        VGA_SYNC_N,						//	VGA SYNC
        VGA_R,   						//	VGA Red[9:0]
        VGA_G,	 						//	VGA Green[9:0]
        VGA_B   						//	VGA Blue[9:0]
    );

    input			CLOCK_50;				//	50 MHz
    input   [17:0]   SW;
    input   [3:0]   KEY;
	 output 	[17:0]  LEDR;
     output 	[7:0]  LEDG;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output			VGA_CLK;   				//	VGA Clock
    output			VGA_HS;					//	VGA H_SYNC
    output			VGA_VS;					//	VGA V_SYNC
    output			VGA_BLANK_N;			//	VGA BLANK
    output			VGA_SYNC_N;				//	VGA SYNC
    output	[9:0]	VGA_R;   				//	VGA Red[9:0]
    output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
    output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
    
    wire resetn;
    assign resetn = SW[0];
    
    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    reg [2:0] color;
    reg [6:0] x;
    reg [6:0] y;
    reg writeEn;
	
    // for Debugging
	 assign LEDR[17:0] = bee1_offset[17:0];
//	assign LEDR[0] = x == 7'd80;
//    assign LEDR[1] = y == 7'd60;
    // assign LEDG[0] = bee0_load;
    // assign LEDG[1] = bee0_clear;
    // assign LEDG[2] = bee0_waiting;
    // assign LEDG[3] = bee0_done;
	 
//	assign LEDR[17:14] = dir;


    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(color),
            .x(x),
            .y(y),
            .plot(writeEn),
            /* Signals for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";
//		  
//		 assign LEDR[0] = bee0_writeEn;
//		 assign LEDR[1] = bee1_writeEn;
//            
    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    ////////////////////////////////////// WHICH ONE DRAWS ///////////////////////////////////////////////////////////
	 
	 always @(*) begin
		if (bee0_writeEn)
            begin
                x = bee0_x;
                y = bee0_y;
                color = bee0_c;
                writeEn = 1'b1;
            end 
        else if (bee1_writeEn)
            begin
                x = bee1_x;
                y = bee1_y;
                color = bee1_c;
                writeEn = 1'b1;
            end 
	 end
	 
    
    /////////////////////////////////////////// BEE 0 INSTANTIATION //////////////////////////////////////////////////////
    
    wire bee0_clear, bee0_update, bee0_done, bee0_waiting;
    wire bee0_rdout, bee0_writeEn;
    wire [6:0] bee0_x;
    wire [6:0] bee0_y;
    wire [2:0] bee0_c;
    wire [3:0] bee0_dir;

    reg [6:0] bee0_x_in = 7'd80;
    reg [6:0] bee0_y_in = 7'd60;
    reg [3:0] bee0_dir_in   = 4'b0011;
    reg [27:0] bee0_offset  = 28'd0; 

    // Instantiate Rate divider for Bee 0
    rate_divider bee0_rd(
        .clk(CLOCK_50), 
        .load_val(28'd500000), 
        .compare(bee0_offset), 
        .out(bee0_rdout)
    );

    // Instantiate boing for Bee 0
    boingboing bee0_boing(
        .clk(bee0_rdout), 
        .resetn(1'b1), 
        .dir_in(bee0_dir_in), 
        .x(bee0_x), 
        .y(bee0_y), 
        .dir_out(bee0_dir)
    );

    // Instansiate datapath for Bee 0
    datapath bee0_data(
        // Inputs
        .clk(CLOCK_50),
		.resetn(1'b1),
        .done(bee0_done),
        .update(bee0_update),
        .clear(bee0_clear),
		.waiting(bee0_waiting),
        .c_in(3'b100),
        .x_in(bee0_x_in),
        .y_in(bee0_y_in),
        .dir_in(bee0_dir),

        // Outputs
        .x_out(bee0_x),
        .y_out(bee0_y),
        .c_out(bee0_c),
        .writeEn(bee0_writeEn)
    );

    // Instansiate FSM control Bee 0
    control bee0_control(
        // Inputs 
        .clk(CLOCK_50),
		.slowClk(bee0_rdout),
        .resetn(1'b1),
		.moved(| bee0_dir),

        // Outputs
        .update(bee0_update),
        .clear(bee0_clear),
        .done(bee0_done),
		.waiting(bee0_waiting),
    );

    /////////////////////////////////////////// BEE 1 INSTANTIATION //////////////////////////////////////////////////////
    
    wire bee1_clear, bee1_update, bee1_done, bee1_waiting;
    wire bee1_rdout, bee1_writeEn;
    wire [6:0] bee1_x;
    wire [6:0] bee1_y;
    wire [2:0] bee1_c;
    wire [3:0] bee1_dir;

    reg [6:0] bee1_x_in = 7'd80;
    reg [6:0] bee1_y_in = 7'd60;
    reg [3:0] bee1_dir_in   = 4'b0011;
    wire [27:0] bee1_offset;
	
	assign bee1_offset = {11'd0, SW[17:1]};

    // Instantiate Rate divider for Bee 1
    rate_divider bee1_rd(
        .clk(CLOCK_50), 
        .load_val(28'd500000), 
        .compare(bee1_offset), 
        .out(bee1_rdout)
    );

    // Instantiate boing for Bee 1
    boingboing bee1_boing(
        .clk(bee1_rdout), 
        .resetn(1'b1), 
        .dir_in(bee1_dir_in), 
        .x(bee1_x), 
        .y(bee1_y), 
        .dir_out(bee1_dir)
    );

    // Instansiate datapath for Bee 1
    datapath bee1_data(
        // Inputs
        .clk(CLOCK_50),
		.resetn(1'b1),
        .done(bee1_done),
        .update(bee1_update),
        .clear(bee1_clear),
		.waiting(bee1_waiting),
        .c_in(3'b110),
        .x_in(bee1_x_in),
        .y_in(bee1_y_in),
        .dir_in(bee1_dir),

        // Outputs
        .x_out(bee1_x),
        .y_out(bee1_y),
        .c_out(bee1_c),
        .writeEn(bee1_writeEn)
    );

    // Instansiate FSM control Bee 1
    control bee1_control(
        // Inputs 
        .clk(CLOCK_50),
		.slowClk(bee1_rdout),
        .resetn(1'b1),
		.moved(| bee1_dir),

        // Outputs
        .update(bee1_update),
        .clear(bee1_clear),
        .done(bee1_done),
		.waiting(bee1_waiting),
    );

    
    
    
endmodule