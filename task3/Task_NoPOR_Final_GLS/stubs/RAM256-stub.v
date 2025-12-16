// SPDX-FileCopyrightText: 2025 Efabless Corporation/VSD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
(* blackbox *)
module RAM256 (
    inout VPWR,	    /* 1.8V domain */
    inout VGND,
    input   wire        CLK,    // FO: 2
    input   wire [3:0]  WE0,     // FO: 2
    input               EN0,     // FO: 2
    input   wire [7:0]  A0,      // FO: 5
    input   wire [31:0] Di0,     // FO: 2
    output  wire [31:0] Do0

);
  
endmodule
