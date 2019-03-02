-----------------------------------------------------------------------
--  util-commands-tests - Test for commands
--  Copyright (C) 2018 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with GNAT.Command_Line;
with Util.Test_Caller;
with Util.Commands.Parsers.GNAT_Parser;
with Util.Commands.Drivers;
package body Util.Commands.Tests is

   package Caller is new Util.Test_Caller (Test, "Commands");

   type Test_Context_Type is record
      Number  : Integer;
      Success : Boolean := False;
   end record;

   package Test_Command is new
     Util.Commands.Drivers (Context_Type => Test_Context_Type,
                            Config_Parser => Util.Commands.Parsers.GNAT_Parser.Config_Parser,
                            Driver_Name  => "test");

   type Test_Command_Type is new Test_Command.Command_Type with record
      Opt_Count : aliased Integer := 0;
      Opt_V     : aliased Boolean := False;
      Opt_N     : aliased Boolean := False;
      Expect_V  : Boolean := False;
      Expect_N  : Boolean := False;
      Expect_C  : Integer := 0;
      Expect_A  : Integer := 0;
      Expect_Help : Boolean := False;
   end record;

   overriding
   procedure Execute (Command   : in out Test_Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Test_Context_Type);

   --  Setup the command before parsing the arguments and executing it.
   procedure Setup (Command : in out Test_Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Test_Context_Type);

   --  Write the help associated with the command.
   procedure Help (Command   : in out Test_Command_Type;
                   Context   : in out Test_Context_Type);

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Util.Commands.Driver.Execute",
                       Test_Execute'Access);
      Caller.Add_Test (Suite, "Test Util.Commands.Driver.Help",
                       Test_Help'Access);
      Caller.Add_Test (Suite, "Test Util.Commands.Driver.Usage",
                       Test_Usage'Access);
   end Add_Tests;

   overriding
   procedure Execute (Command   : in out Test_Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Test_Context_Type) is
      pragma Unreferenced (Name);
   begin
      Context.Success := Command.Opt_Count = Command.Expect_C and
        Command.Opt_V = Command.Expect_V and
        Command.Opt_N = Command.Expect_N and
        Args.Get_Count = Command.Expect_A and
        not Command.Expect_Help;
   end Execute;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   procedure Setup (Command : in out Test_Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Test_Context_Type) is
      pragma Unreferenced (Context);
   begin
      GNAT.Command_Line.Define_Switch (Config      => Config,
                                       Switch      => "-c:",
                                       Long_Switch => "--count=",
                                       Help        => "Number option",
                                       Section     => "",
                                       Initial     => Integer (0),
                                       Default     => Integer (10),
                                       Output      => Command.Opt_Count'Access);
      GNAT.Command_Line.Define_Switch (Config      => Config,
                                       Switch      => "-v",
                                       Long_Switch => "--verbose",
                                       Help        => "Verbose option",
                                       Section     => "",
                                       Output      => Command.Opt_V'Access);
      GNAT.Command_Line.Define_Switch (Config      => Config,
                                       Switch      => "-n",
                                       Long_Switch => "--not",
                                       Help        => "Not option",
                                       Section     => "",
                                       Output      => Command.Opt_N'Access);
   end Setup;

   --  ------------------------------
   --  Write the help associated with the command.
   --  ------------------------------
   procedure Help (Command   : in out Test_Command_Type;
                   Context   : in out Test_Context_Type) is

   begin
      Context.Success := Command.Expect_Help;
   end Help;

   --  ------------------------------
   --  Tests when the execution of commands.
   --  ------------------------------
   procedure Test_Execute (T : in out Test) is
      C1    : aliased Test_Command_Type;
      C2    : aliased Test_Command_Type;
      D     : Test_Command.Driver_Type;
      Args  : String_Argument_List (500, 30);
   begin
      D.Set_Description ("Test command");
      D.Add_Command ("list", C1'Unchecked_Access);
      D.Add_Command ("print", C2'Unchecked_Access);

      declare
         Ctx   : Test_Context_Type;
      begin
         C1.Expect_V := True;
         C1.Expect_N := True;
         C1.Expect_C := 4;
         C1.Expect_A := 2;
         Initialize (Args, "list --count=4 -v -n test titi");
         D.Execute ("list", Args, Ctx);
         T.Assert (Ctx.Success, "Some arguments not parsed correctly");
      end;

      declare
         Ctx   : Test_Context_Type;
      begin
         C1.Expect_V := False;
         C1.Expect_N := True;
         C1.Expect_C := 8;
         C1.Expect_A := 3;
         Initialize (Args, "list -c 8 -n test titi last");
         D.Execute ("list", Args, Ctx);
         T.Assert (Ctx.Success, "Some arguments not parsed correctly");
      end;

   end Test_Execute;

   --  ------------------------------
   --  Test execution of help.
   --  ------------------------------
   procedure Test_Help (T : in out Test) is
      C1    : aliased Test_Command_Type;
      C2    : aliased Test_Command_Type;
      H     : aliased Test_Command.Help_Command_Type;
      D     : Test_Command.Driver_Type;
      Args  : String_Argument_List (500, 30);
   begin
      D.Set_Description ("Test command");
      D.Add_Command ("list", C1'Unchecked_Access);
      D.Add_Command ("print", C2'Unchecked_Access);
      D.Add_Command ("help", H'Unchecked_Access);
      declare
         Ctx   : Test_Context_Type;
      begin
         C1.Expect_Help := True;
         Initialize (Args, "help list");
         D.Execute ("help", Args, Ctx);
         T.Assert (Ctx.Success, "Some arguments not parsed correctly");
      end;

      declare
         Ctx   : Test_Context_Type;
      begin
         C2.Expect_Help := True;
         Initialize (Args, "help print");
         D.Execute ("help", Args, Ctx);
         T.Assert (Ctx.Success, "Some arguments not parsed correctly");
      end;
   end Test_Help;

   --  ------------------------------
   --  Test usage operation.
   --  ------------------------------
   procedure Test_Usage (T : in out Test) is
      C1    : aliased Test_Command_Type;
      C2    : aliased Test_Command_Type;
      H     : aliased Test_Command.Help_Command_Type;
      D     : Test_Command.Driver_Type;
      Args  : String_Argument_List (500, 30);
   begin
      D.Set_Description ("Test command");
      D.Add_Command ("list", C1'Unchecked_Access);
      D.Add_Command ("print", C2'Unchecked_Access);
      D.Add_Command ("help", H'Unchecked_Access);
      Args.Initialize (Line => "cmd list");
      declare
         Ctx   : Test_Context_Type;
      begin
         D.Usage (Args, Ctx);
         C1.Expect_Help := True;
         Initialize (Args, "help list");
         D.Execute ("help", Args, Ctx);
         T.Assert (Ctx.Success, "Some arguments not parsed correctly");
      end;
   end Test_Usage;

end Util.Commands.Tests;