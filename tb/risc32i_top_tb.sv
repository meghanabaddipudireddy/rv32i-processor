module top_tb;

    logic clk, rst;

    top uut (.clk(clk), .rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
    end

    initial begin

        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;

        // run enough cycles 
        repeat(20) @(posedge clk);
        #1
        
        assert (uut.u_reg_file.registers[1] == 32'd5)
            else $error("FAIL: x1 expected 5 got %0d", uut.u_reg_file.registers[1]);

        assert (uut.u_reg_file.registers[2] == 32'd3)
            else $error("FAIL: x2 expected 3 got %0d", uut.u_reg_file.registers[2]);

        assert (uut.u_reg_file.registers[3] == 32'd8)
            else $error("FAIL: x3 expected 8 got %0d", uut.u_reg_file.registers[3]);

        assert (uut.u_reg_file.registers[4] == 32'd2)
            else $error("FAIL: x4 expected 2 got %0d", uut.u_reg_file.registers[4]);

        assert (uut.u_reg_file.registers[5] == 32'd1)
            else $error("FAIL: x5 expected 1 got %0d", uut.u_reg_file.registers[5]);

        assert (uut.u_reg_file.registers[6] == 32'd7)
            else $error("FAIL: x6 expected 7 got %0d", uut.u_reg_file.registers[6]);

        assert (uut.u_reg_file.registers[7] == 32'd6)
            else $error("FAIL: x7 expected 6 got %0d", uut.u_reg_file.registers[7]);

        assert (uut.u_reg_file.registers[8] == 32'd5)
            else $error("FAIL: x8 expected 5 got %0d", uut.u_reg_file.registers[8]);

        assert (uut.u_reg_file.registers[9] == 32'd0)
            else $error("FAIL: x9 should be 0 (branch skipped it) got %0d", uut.u_reg_file.registers[9]);

        assert (uut.u_reg_file.registers[10] == 32'd42)
            else $error("FAIL: x10 expected 42 got %0d", uut.u_reg_file.registers[10]);

        $display("ALL TESTS PASSED");

        $finish;
    end
endmodule