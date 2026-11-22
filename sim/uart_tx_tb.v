`timescale 1ns/1ns

module uart_tx_tb;

    reg clk;
    reg rst;
    reg send;
    reg [7:0] data;
    wire tx;
    wire busy;

    uart_tx uut (
        .clk(clk),
        .rst(rst),
        .send(send),
        .data(data),
        .tx(tx),
        .busy(busy)
    );

    
    always #10 clk = ~clk;

    initial begin
        
        clk = 0;
        rst = 1;
        send = 0;
        data = 8'b10101010;

        
        #50;
        rst = 0;

        
        #100;
        send = 1;

        
        #20;
        send = 0;

        
        #100000; 

        $finish;
    end

endmodule
