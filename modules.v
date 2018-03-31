///////////////////////////////////// MECHANICS ///////////////////////////////////////////////////////
module mechanics(
    input clk,
    input resetn,

    // User 
    input [6:0] user_x,
    input [6:0] user_y,
    input [2:0] user_c,
    input [2:0] user_writeEn,

    // Bees
    input [6:0] bee0_x,
    input [6:0] bee0_y,
    input [2:0] bee0_c,
    input [2:0] bee0_writeEn,


    // Outputs for game
    output reg game_reset,
    output reg game_over,
    output reg [1:0] lives,
    output reg [7:0] score,
    output reg [7:0] high_score

    // // Outputs for VGA
    // output reg [6:0] vga_x,
    // output reg [6:0] vga_y,
    // output reg [2:0] vga_c,
    // output reg vga_writeEn
    );

    initial begin
        lives       = 2'b11;
        score       = 8'h00;
        high_score  = 8'h00;
    end

    // Placeholder values, need to change these to
    // appropriate screen boundary vaues in pixels
    localparam LEFTEDGE     = 7'd1;   
    localparam RIGHTEDGE    = 7'd124;   // x goes from 0 - 127
    localparam TOPEDGE      = 7'd1;
    localparam BOTTOMEDGE   = 7'd116;   // y goes from 0 - 120
    

    wire bees_collided, edges_collided;
    // Checking for collisions between all bees
    // (can do && with bees_enable index later...)
    assign bees_collided = 
        (   (user_x >= bee0_x - 2'd3) && (user_x <= bee0_x + 2'd3)
        &&  (user_y >= bee0_y - 2'd3) && (user_y <= bee0_y + 2'd3));


    // Just for testing without any bees
    // assign bees_collided = 1'b0;


    assign edges_collided = 
        (user_x >= RIGHTEDGE) ||
        (user_x <= LEFTEDGE)  ||
        (user_y <= TOPEDGE)   ||
        (user_y >= BOTTOMEDGE);

    assign collided = bees_collided || edges_collided;

    reg cnt;
    reg rscount = 10'd0;
    always @(posedge clk)
        begin
            if (rscount == 10'd1111111111)
				begin
                rscount = 10'd0;
					 cnt = 1'b0;
				end
            else if (cnt)
                rscount = rscount + 1'b1;
        end

    // Actual logic for game events here
    // Including collisions, game over, etc...
    always @(*)
    begin
        game_reset = 1'b0;
        game_over = 1'b0;

        if (cnt)
            game_reset = 1'b1;

        // If reset is pressed
        else if (resetn)
            begin
                game_reset = 1'b1;
                score      = 1'b0;
                lives      = 2'b11;
            end
        
        // If player has collided with something 
        else if (collided)
            begin
                // If no more lives, want to end game (TODO)
                if (lives == 2'b01)
                    begin
                        cnt = 1'b1; 
                        game_over = 1'b1;		// Figure out Game over. Maybe new state in FSM?
                        game_reset = 1'b1;      
                        lives = 2'b11;        // For now just resetting lives
                        score = 8'h00;
                    end
                // Else just reset and reduce one life
                else
                    begin
                        game_reset = 1'b1;
                        lives = lives - 1'b1;
                    end
            end

        // Update high score (Hopefully useful after scoring works)
        if (score >= high_score)
            high_score = score;
    end

endmodule

//////////////////////////////////////// DATAPATH /////////////////////////////////////////////////////

module datapath(
    input clk,
    input update,
    input clear,
    input bee,
	input waiting,
    input resetn,
    input [2:0] c_in,
    input [2:0] c2_in,
    input [6:0] x_in,
    input [6:0] y_in,
    input [3:0] dir_in,
    output [6:0] x_out,
    output [6:0] y_out,
    output reg [2:0] c_out,
    output reg writeEn,
    output reg done
    );

    // input registers
    reg [3:0] offset = 4'b0000;
    reg [2:0] c_val;
    reg [6:0] x_val;
    reg [6:0] y_val;
	 
	 reg up = 1'b1;
	 
    // Registers x, y, c with respective input logic
    always@(posedge clk) begin
	 
		writeEn = 1'b0;

        if (~resetn)
            begin
                writeEn = 1'b1;
					 c_out = 3'b000;
					 up = 1'b1;
            end

        else begin
            if (clear)
                begin
                    c_out <= 3'b000;
                    writeEn <= 1'b1;
                end
            else if (update)  // UPDATE HERE
					
					if (up)
						begin
							x_val = x_in;
							y_val = y_in;
							up = 1'b0;
						end
						
                else begin
                    writeEn =	 1'b0;
                    if (dir_in[0] == 1'b1)  // RIGHT
                        x_val = x_val + 1;
                    if (dir_in[3] == 1'b1)	// LEFT
                        x_val = x_val - 1;
                    if (dir_in[2] == 1'b1)	// DOWN
                        y_val = y_val + 1;
                    if (dir_in[1] == 1'b1)	// UP
                        y_val = y_val - 1;
                end 
            else if (~waiting)      // DRAWING STATE
                begin
                    writeEn = 1'b1;
                    // Checks what type of object it is and draws shape
                    if (bee)
                        c_out = (offset[0]) ? c2_in : c_in;
                    else
                        c_out = c_in;
                        
                end
                
        end
    end

    // Increment offset, first 2 bits for x,2nd for y
    always@(posedge clk) 
	 begin
        if (waiting || update)
            done = 1'b0;
			
        if (~waiting && ~update && ~done) 
		  begin
		  
            if (offset == 4'b1111)
            begin
                offset <= 4'b0000;
                done = 1'b1;
            end 
            else
                offset = offset + 1'b1;
        end
    end

        assign x_out = x_val + offset[1:0];
        assign y_out = y_val + offset[3:2];

endmodule // datapath

///////////////////////////////////////////////////////// CONTROL ///////////////////////////////////////////////////////////

module control(
    input clk,
	input slowClk,
    input resetn,
    input done,
	input moved,
    output reg  clear,
    output reg update,
	output reg waiting
    );

    reg [2:0] current_state, next_state;

    localparam  S_CLEAR   	= 5'd1,
                S_UPDATE 	= 5'd2,	
                S_DRAW      = 5'd3,
				S_WAIT		= 5'd4;

    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                S_WAIT: next_state = (moved && slowClk) ? S_CLEAR : S_WAIT; // Loop in current state until go signal goes low
                S_CLEAR: next_state = done ? S_UPDATE : S_CLEAR; // Loop in current state until value is input
                S_UPDATE : next_state = S_DRAW;
                S_DRAW: next_state = done ? S_WAIT : S_DRAW; // Draw state, Go back to X
            default:     next_state = S_CLEAR;
        endcase
    end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        clear = 1'b0;
        update = 1'b0;
		waiting = 1'b0;
        case (current_state)
			S_WAIT:     waiting = 1'b1;
            S_CLEAR:    clear = 1'b1;
            S_UPDATE:   update = 1'b1;
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        current_state <= next_state;
    end // state_FFS
endmodule // control

////////////////////////////////////////// RATE DIVIDER ////////////////////////////////////////////////////

module rate_divider(clk, load_val, out);
	input clk;
	input [27:0] load_val;
	output [27:0] out;
	
	reg [27:0] count;
	
    assign out = count;
	
	always @(posedge clk)
	begin
		if (count == 28'h0000000)
			count <= load_val;
		else
			count <= count - 1;
	end
endmodule 