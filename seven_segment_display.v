//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2010 Gandhi Puvvada, EE-Systems, VSoE, USC
//
// This design exercise, its solution, and its test-bench are confidential items.
// They are University of Southern California's (USC's) property. All rights are reserved.
// Students in our courses have right only to complete the exercise and submit it as part of their course work.
// They do not have any right on our exercise/solution or even on their completed solution as the solution contains our exercise.
// Students would be violating copyright laws besides the University's Academic Integrity rules if they post or convey to anyone
// either our exercise or our solution or their solution. 
// 
// THIS COPYRIGHT NOTICE MUST BE RETAINED AS PART OF THIS FILE (AND ITS SOLUTION AND/OR ANY OTHER DERIVED FILE) AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////
//
// A student would be violating the University's Academic Integrity rules if he/she gets help in writing or debugging the code 
// from anyone other than the help from his/her lab partner or his/her teaching team members in completing the exercise(s). 
// However he/she can discuss with fellow students the method of solving the exercise. 
// But writing the code or debugging the code should not be with the help of others. 
// One should never share the code or even look at the code of others (code from classmates or seniors 
// or any code or solution posted online or on GitHub).
// 
// THIS NOTICE OF ACADEMIC INTEGRITY MUST BE RETAINED AS PART OF THIS FILE (AND ITS SOLUTION AND/OR ANY OTHER DERIVED FILE) AT ALL TIMES.
//
//////////////////////////////////////////////////////////////////////////////


`timescale 1 ns / 100 ps

module seven_segment_display (hex, Cout);

input [3:0] hex;
output [7:0] Cout;
reg  Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp;

always @(*) 
	  begin  : seven_segment_display_combo
	  
		case (hex)
				4'b0000	: // Display 0
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b1000_0001; 
				  end
				  
				4'b0001	: // Display 1
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b1111_0011; 
				  end
				  
				4'b0010	: // Display 2
				  begin        
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0100_1001;
				  end
				  
				4'b0011	: // Display 3
				  begin
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0110_0001;
				  end
				  
				4'b0100	: // Display 4
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0011_0011; 
				  end
				  
				4'b0101	: // Display 5
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0010_0101; 
				  end
				  
				4'b0110	: // Display 6
				  begin        
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0000_0101;
				  end
				  
				4'b0111	: // Display 7
				  begin
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b1111_0001;
				  end
				
				4'b1000	: // Display 8
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0000_0001; 
				  end
				  
				4'b1001	: // Display 9
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0010_0001; 
				  end
				  
				4'b1010	: // Display A
				  begin        
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0001_0001;
				  end
				  
				4'b1011	: // Display b
				  begin
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0000_0111;
				  end
				  
				4'b1100	: // Display C
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b1000_1101; 
				  end
				  
				4'b1101	: // Display d
				  begin
					{Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0100_0011; 
				  end
				  
				4'b1110	: // Display E
				  begin        
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0000_1101;
				  end
				  
				4'b1111	: // Display F
				  begin
				    {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp} <= 8'b0001_1101;
				  end
		endcase
	   end 

assign Cout = {Cg, Cf, Ce, Cd, Cc, Cb, Ca, dp};

endmodule 