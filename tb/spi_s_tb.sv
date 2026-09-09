module tb_spi_s;
logic clk=0,rst_n=0,cs=1,sclk=0,mosi=0;
logic miso;
spi_s dut(.clk,.rst_n,.cs,.sclk,.mosi,.miso);
always #5 clk=~clk;

    initial begin
        rst_n = 0;
        #20 rst_n = 1;

        @(posedge clk);
        cs <= 0;   // select the slave

        repeat (5) @(posedge clk);
        $display("With cs=0 -> miso=%b (expect 1)", miso);

        @(posedge clk);
        cs <= 1;   // deselect

        repeat (5) @(posedge clk);
        $display("With cs=1 -> miso=%b (expect 0)", miso);

        $finish;
    end

endmodule
