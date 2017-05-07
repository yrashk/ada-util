-----------------------------------------------------------------------
--  util-commands-consoles-text - Text console interface
--  Copyright (C) 2014, 2017 Stephane Carrez
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
with Ada.Text_IO;
generic
package Util.Commands.Consoles.Text is

   type Console_Type is new Util.Commands.Consoles.Console_Type with private;

   --  Report an error message.
   overriding
   procedure Error (Console : in out Console_Type;
                    Message : in String);

   --  Report a notice message.
   overriding
   procedure Notice (Console : in out Console_Type;
                     Kind    : in Notice_Type;
                     Message : in String);

   --  Print the field value for the given field.
   overriding
   procedure Print_Field (Console : in out Console_Type;
                          Field   : in Field_Type;
                          Value   : in String;
                          Justify : in Justify_Type := J_LEFT);

   --  Print the title for the given field.
   overriding
   procedure Print_Title (Console : in out Console_Type;
                          Field   : in Field_Type;
                          Title   : in String);

   --  Start a new title in a report.
   overriding
   procedure Start_Title (Console : in out Console_Type);

   --  Finish a new title in a report.
   procedure End_Title (Console : in out Console_Type);

   --  Start a new row in a report.
   overriding
   procedure Start_Row (Console : in out Console_Type);

   --  Finish a new row in a report.
   overriding
   procedure End_Row (Console : in out Console_Type);

private

   type Console_Type is new Util.Commands.Consoles.Console_Type with record
      File : Ada.Text_IO.File_Type;
   end record;

end Util.Commands.Consoles.Text;
