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

        // run enough cycles for all instructions
        repeat(30) @(posedge clk);
        #1;

        // ── BRANCH TAKEN TEST ──
        // x1 and x2 set correctly before branch
        assert (uut.u_reg_file.registers[1] == 32'd5)
            else $error("FAIL: x1 expected 5 got %0d", uut.u_reg_file.registers[1]);

        assert (uut.u_reg_file.registers[2] == 32'd5)
            else $error("FAIL: x2 expected 5 got %0d", uut.u_reg_file.registers[2]);

        // x3 should be 0 — first instruction after branch was flushed
        assert (uut.u_reg_file.registers[3] == 32'd0)
            else $error("FAIL: x3 should be 0 (flushed), got %0d", uut.u_reg_file.registers[3]);

        // x4 should be 0 — second instruction after branch was flushed
        assert (uut.u_reg_file.registers[4] == 32'd0)
            else $error("FAIL: x4 should be 0 (flushed), got %0d", uut.u_reg_file.registers[4]);

        // x5 should be 15 — branch target executed correctly
        assert (uut.u_reg_file.registers[5] == 32'd15)
            else $error("FAIL: x5 expected 15 got %0d", uut.u_reg_file.registers[5]);

        $display("BRANCH TAKEN TEST PASSED");

        // ── BRANCH NOT TAKEN TEST ──
        // x6 = 5, x7 = 3, they are not equal so branch should not be taken
        assert (uut.u_reg_file.registers[6] == 32'd5)
            else $error("FAIL: x6 expected 5 got %0d", uut.u_reg_file.registers[6]);

        assert (uut.u_reg_file.registers[7] == 32'd3)
            else $error("FAIL: x7 expected 3 got %0d", uut.u_reg_file.registers[7]);

        // x8 should be 8 — instruction after branch executed since branch not taken
        assert (uut.u_reg_file.registers[8] == 32'd8)
            else $error("FAIL: x8 expected 8 (branch not taken, should execute) got %0d", uut.u_reg_file.registers[8]);

        $display("BRANCH NOT TAKEN TEST PASSED");

        $display("ALL BRANCH FLUSH TESTS PASSED");
        $finish;
    end

endmodule