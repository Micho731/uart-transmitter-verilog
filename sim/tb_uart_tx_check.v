`timescale 1ns/1ps
// Self-checking testbench for uart_tx (50 MHz clock, 9600 baud, 8N1).
// Acts as a receiver: waits for each start bit, samples the line in the
// middle of every bit, and compares the decoded byte with the byte sent.
module tb_uart_tx_check;
    localparam CLK_NS   = 20;                 // 50 MHz
    localparam BIT_CLKS = 5208;               // counter runs 0..5207
    localparam BIT_NS   = BIT_CLKS * CLK_NS;  // 104 160 ns per bit

    reg clk = 0, rst = 1, send = 0;
    reg [7:0] data = 0;
    wire tx, busy;

    uart_tx uut (.clk(clk), .rst(rst), .send(send), .data(data), .tx(tx), .busy(busy));
    always #(CLK_NS/2) clk = ~clk;

    reg [7:0] bytes [0:4];
    integer i, b, errors = 0;
    reg [7:0] rx;
    time t_start, t_stop_end;

    task send_byte(input [7:0] value);
        begin
            @(negedge clk); data = value; send = 1;
            @(negedge clk); send = 0;
        end
    endtask

    task receive_and_check(input [7:0] expected);
        begin
            @(negedge tx); t_start = $time;               // start bit edge
            #(BIT_NS/2);
            if (tx !== 1'b0) begin $display("FAIL start bit"); errors = errors + 1; end
            for (b = 0; b < 8; b = b + 1) begin           // LSB first
                #(BIT_NS); rx[b] = tx;
            end
            #(BIT_NS);
            if (tx !== 1'b1) begin $display("FAIL stop bit"); errors = errors + 1; end
            @(negedge busy); t_stop_end = $time;
            if (rx === expected)
                $display("PASS  sent 0x%02h  received 0x%02h  frame %0.1f us", expected, rx, (t_stop_end - t_start)/1000.0);
            else begin
                $display("FAIL  sent 0x%02h  received 0x%02h", expected, rx); errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx_check);
        bytes[0] = 8'hAA; bytes[1] = 8'h55; bytes[2] = 8'h00; bytes[3] = 8'hFF; bytes[4] = 8'h4D;
        #100 rst = 0;
        #100;
        if (tx !== 1'b1 || busy !== 1'b0) begin $display("FAIL idle state"); errors = errors + 1; end
        for (i = 0; i < 5; i = i + 1) begin
            fork
                send_byte(bytes[i]);
                receive_and_check(bytes[i]);
            join
            #(BIT_NS);
        end
        $display("Bit time %0d ns -> %0.1f baud (target 9600, error %0.3f %%)", BIT_NS, 1.0e9/BIT_NS, (1.0e9/BIT_NS - 9600)/96.0);
        if (errors == 0) $display("ALL TESTS PASSED (5 bytes)");
        else             $display("%0d ERRORS", errors);
        $finish;
    end
endmodule
