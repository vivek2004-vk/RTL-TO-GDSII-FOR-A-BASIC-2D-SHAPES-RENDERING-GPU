// Module: command_interface
// Description: Parses a 128-bit command input to extract shape drawing parameters
//              (shape type, coordinates, color, etc.) and generates a start signal.
//              Operates synchronously with clock and includes reset functionality.
// Inputs:
//   - clk: Clock signal for synchronous operation
//   - rst: Active-high asynchronous reset
//   - cmd_valid: When high, indicates cmd_data is valid and should be parsed
//   - cmd_data: 128-bit command input with fields:
//               [127:124] - shape_type (4 bits)
//               [123:116] - x0 (8 bits)
//               [115:108] - y0 (8 bits)
//               [107:100] - x1 (8 bits)
//               [99:92]   - y1 (8 bits)
//               [91:84]   - x2 (8 bits)
//               [83:76]   - y2 (8 bits)
//               [75]      - fill_enable (1 bit)
//               [74:51]   - color (24 bits, RGB)
//               [50:27]   - bg_color (24 bits, RGB)
//               [26:0]    - unused (padding)
// Outputs:
//   - start: High for one cycle when a valid command is parsed
//   - shape_type: 4-bit shape identifier (e.g., 1=line, 2=rect)
//   - x0, y0, x1, y1, x2, y2: 8-bit coordinates for shape vertices
//   - fill_enable: Enables filled shapes when high
//   - color: 24-bit RGB color for shape
//   - bg_color: 24-bit RGB background color (used for clear commands)

module command_interface (
    input  wire        clk,          // Clock input
    input  wire        rst,          // Active-high reset
    input  wire        cmd_valid,    // Command valid signal
    input  wire [127:0] cmd_data,    // 128-bit command input
    output reg         start,        // Start signal to controller
    output reg [3:0]   shape_type,   // Shape type (e.g., 1=line, 2=rect)
    output reg [7:0]   x0, y0,       // Coordinates for vertex 0
    output reg [7:0]   x1, y1,       // Coordinates for vertex 1
    output reg [7:0]   x2, y2,       // Coordinates for vertex 2
    output reg         fill_enable,  // Enable filled shape drawing
    output reg [23:0]  color,        // Shape color (RGB)
    output reg [23:0]  bg_color      // Background color (RGB)
);

    // Sequential logic for command parsing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs to default values
            start <= 1'b0;
            shape_type <= 4'b0;
            x0 <= 8'b0;
            y0 <= 8'b0;
            x1 <= 8'b0;
            y1 <= 8'b0;
            x2 <= 8'b0;
            y2 <= 8'b0;
            fill_enable <= 1'b0;
            color <= 24'b0;
            bg_color <= 24'b0;
        end else begin
            if (cmd_valid) begin
                // Parse cmd_data when cmd_valid is high
                start <= 1'b1;                    // Assert start for one cycle
                shape_type <= cmd_data[127:124];  // Extract shape type
                x0 <= cmd_data[123:116];          // Extract x0 coordinate
                y0 <= cmd_data[115:108];          // Extract y0 coordinate
                x1 <= cmd_data[107:100];          // Extract x1 coordinate
                y1 <= cmd_data[99:92];            // Extract y1 coordinate
                x2 <= cmd_data[91:84];            // Extract x2 coordinate
                y2 <= cmd_data[83:76];            // Extract y2 coordinate
                fill_enable <= cmd_data[75];      // Extract fill enable
                color <= cmd_data[74:51];         // Extract shape color
                bg_color <= cmd_data[50:27];      // Extract background color
            end else begin
                // Deassert start when no valid command
                start <= 1'b0;
            end
        end
    end

endmodule

//TESTBENCH
// Testbench: command_interface_tb
// Description: Tests the command_interface module by providing 128-bit commands
//              and verifying parsed outputs. Generates VCD file for GTKWave.
// Usage: Compile with iverilog (iverilog -o cmd_sim command_interface.v command_interface_tb.v)
//        Run with vvp (vvp cmd_sim), view with gtkwave (gtkwave command_interface_tb.vcd)

module command_interface_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100 MHz)

    // Signals
    reg        clk;          // Clock
    reg        rst;          // Reset
    reg        cmd_valid;    // Command valid
    reg [127:0] cmd_data;    // 128-bit command input
    wire       start;        // Start output
    wire [3:0] shape_type;   // Shape type output
    wire [7:0] x0, y0;       // Vertex 0 coordinates
    wire [7:0] x1, y1;       // Vertex 1 coordinates
    wire [7:0] x2, y2;       // Vertex 2 coordinates
    wire       fill_enable;  // Fill enable output
    wire [23:0] color;       // Shape color output
    wire [23:0] bg_color;    // Background color output

    // Instantiate the DUT (Device Under Test)
    command_interface dut (
        .clk(clk),
        .rst(rst),
        .cmd_valid(cmd_valid),
        .cmd_data(cmd_data),
        .start(start),
        .shape_type(shape_type),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .fill_enable(fill_enable),
        .color(color),
        .bg_color(bg_color)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk; // Toggle every 5ns
    end

    // Test stimulus
    initial begin
        // Setup VCD dump for GTKWave
        $dumpfile("command_interface_tb.vcd");
        $dumpvars(0, command_interface_tb);

        // Initialize signals
        rst = 1;
        cmd_valid = 0;
        cmd_data = 128'b0;
        #20; // Hold reset for two cycles
        rst = 0;
        #10; // Wait one cycle after reset
        $display("Starting Command Interface Testbench");

        // Test 1: Line command (0,0) to (10,10), white, no fill
        $display("\nTest 1: Line command (0,0) to (10,10)");
        cmd_data = {4'h1, 8'h00, 8'h00, 8'h0A, 8'h0A, 8'h00, 8'h00, 1'b0, 24'hFFFFFF, 24'h000000, 27'h0};
        cmd_valid = 1;
        @(posedge clk); // Apply command at clock edge
        #1; // Wait for outputs to settle
        $display("start=%b, shape_type=%0d, x0=%0d, y0=%0d, x1=%0d, y1=%0d, x2=%0d, y2=%0d, fill_enable=%b, color=%h, bg_color=%h",
                 start, shape_type, x0, y0, x1, y1, x2, y2, fill_enable, color, bg_color);
        cmd_valid = 0;

        // Wait before next test
        #30;

        // Test 2: Rectangle command (5,5) to (15,15), red, fill enabled
        $display("\nTest 2: Rectangle command (5,5) to (15,15)");
        cmd_data = {4'h2, 8'h05, 8'h05, 8'h0F, 8'h0F, 8'h00, 8'h00, 1'b1, 24'hFF0000, 24'h000000, 27'h0};
        cmd_valid = 1;
        @(posedge clk);
        #1;
        $display("start=%b, shape_type=%0d, x0=%0d, y0=%0d, x1=%0d, y1=%0d, x2=%0d, y2=%0d, fill_enable=%b, color=%h, bg_color=%h",
                 start, shape_type, x0, y0, x1, y1, x2, y2, fill_enable, color, bg_color);
        cmd_valid = 0;

        // Test 3: Circle command (center=20,20, radius=10), blue, no fill
        $display("\nTest 3: Circle command (center=20,20, radius=10)");
        cmd_data = {4'h4, 8'h14, 8'h14, 8'h0A, 8'h00, 8'h00, 8'h00, 1'b0, 24'h0000FF, 24'h000000, 27'h0};
        cmd_valid = 1;
        @(posedge clk);
        #1;
        $display("start=%b, shape_type=%0d, x0=%0d, y0=%0d, x1=%0d, y1=%0d, x2=%0d, y2=%0d, fill_enable=%b, color=%h, bg_color=%h",
                 start, shape_type, x0, y0, x1, y1, x2, y2, fill_enable, color, bg_color);
        cmd_valid = 0;

        // End simulation
        #20;
        $display("Testbench finished!");
        $finish;
    end

endmodule

