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

        // run enough cycles
        repeat(20) @(posedge clk);
        #1;

        // EX→EX forwarding — x1 forwarded immediately to next instruction
        assert (uut.u_reg_file.registers[1] == 32'd5)
            else $error("FAIL: x1 expected 5 got %0d", uut.u_reg_file.registers[1]);

        // EX→EX forwarding — x2 = x1 + x1 = 10
        assert (uut.u_reg_file.registers[2] == 32'd20)
            else $error("FAIL: x2 expected 20 got %0d", uut.u_reg_file.registers[2]);

        // MEM→EX forwarding — x3 = x5 + x2 = 5 + 20 = 25, then overwritten to 6
        assert (uut.u_reg_file.registers[3] == 32'd6)
            else $error("FAIL: x3 expected 6 got %0d", uut.u_reg_file.registers[3]);

        assert (uut.u_reg_file.registers[4] == 32'd3)
            else $error("FAIL: x4 expected 3 got %0d", uut.u_reg_file.registers[4]);

        assert (uut.u_reg_file.registers[5] == 32'd5)
            else $error("FAIL: x5 expected 5 got %0d", uut.u_reg_file.registers[5]);

        $display("FORWARDING TEST PASSED");
        $finish;
    end

endmodule

