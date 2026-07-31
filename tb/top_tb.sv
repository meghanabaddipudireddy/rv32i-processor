module top_tb;

    logic clk, rst;

    top uut (.clk(clk), .rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);

        // reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;

        // run enough cycles for all instructions to complete
        // 6 instructions + 4 pipeline stages = need about 10 cycles
        repeat(15) @(posedge clk);
        #1;

        // check each register
        assert (uut.u_reg_file.registers[1] == 32'd5)
            else $error("FAIL: x1 expected 5 got %0d", uut.u_reg_file.registers[1]);

        assert (uut.u_reg_file.registers[2] == 32'd6)
            else $error("FAIL: x2 expected 6 got %0d", uut.u_reg_file.registers[2]);

        assert (uut.u_reg_file.registers[3] == 32'd7)
            else $error("FAIL: x3 expected 7 got %0d", uut.u_reg_file.registers[3]);

        assert (uut.u_reg_file.registers[4] == 32'd8)
            else $error("FAIL: x4 expected 8 got %0d", uut.u_reg_file.registers[4]);

        assert (uut.u_reg_file.registers[5] == 32'd9)
            else $error("FAIL: x5 expected 9 got %0d", uut.u_reg_file.registers[5]);

        assert (uut.u_reg_file.registers[6] == 32'd10)
            else $error("FAIL: x6 expected 10 got %0d", uut.u_reg_file.registers[6]);

        $display("PIPELINE TEST PASSED — all registers correct");
        $finish;
    end

endmodule