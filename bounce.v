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
    wire [2:0] colour;
    wire [6:0] x;
    wire [6:0] y;
    wire writeEn;

    // for Debugging
	assign LEDR[0] = x == 7'd80;
    assign LEDR[1] = y == 7'd60;
    // assign LEDG[0] = player_load;
    // assign LEDG[1] = player_clear;
    // assign LEDG[2] = player_waiting;
    // assign LEDG[3] = player_done;
	 
	assign LEDR[17:14] = dir;


    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(colour),
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
            
    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.
    

    
    wire player_clear;
    wire player_update;
    wire player_done;
	wire player_waiting;
    
    wire tenHz;
    
    rate_divider tenmil(CLOCK_50, 28'd500000, tenHz);
	 
	reg [3:0] dir = 4'b0011;
	
	always @(posedge tenHz)
	begin
        if (~resetn)
            dir = 4'b0011;
        else begin
            if (x >= 7'd124)
            begin
                dir[0] = 1'b0;
                dir[3] = 1'b1;
            end
            else if (x <= 7'd1)
            begin
                dir[0] = 1'b1;
                dir[3] = 1'b0;
            end
            
            if (y == 7'd116)
            begin
                dir[1] = 1'b1;
                dir[2] = 1'b0;
            end
            else if (y == 7'd0)
            begin
                dir[1] = 1'b0;
                dir[2] = 1'b1;
            end
        end
	
	end

    // Instansiate datapath
    datapath d0(
        // Inputs
        .clk(CLOCK_50),
		.resetn(SW[0]),
        .done(player_done),
        .update(player_update),
        .clear(player_clear),
		.waiting(player_waiting),
        .c_in(SW[9:7]),
        .x_in(7'd80),
        .y_in(7'd60),
        .dir_in(dir),//dir),

        // Outputs
        .x_out(x),
        .y_out(y),
        .c_out(colour),
        .writeEn(writeEn)
    );

    // Instansiate FSM control
    control c0(
        // Inputs 
        .clk(CLOCK_50),
		.slowClk(tenHz),
        .resetn(SW[0]),
		.moved(| dir),//~(& KEY[3:0])),

        // Outputs
        .update(player_update),
        .clear(player_clear),
        .done(player_done),
		.waiting(player_waiting),
        .led(LEDG[4:0])
    );
    
endmodule