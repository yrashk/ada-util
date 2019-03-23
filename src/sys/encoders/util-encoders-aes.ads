-----------------------------------------------------------------------
--  util-encoders-aes -- AES encryption and decryption
--  Copyright (C) 2017, 2019 Stephane Carrez
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
with Interfaces;
private with Ada.Finalization;

--  The <b>Util.Encodes.SHA1</b> package generates SHA-1 hash according to
--  RFC3174 or [FIPS-180-1].
package Util.Encoders.AES is

   type AES_Mode is (ECB, CBC, PCBC, CFB, OFB, CTR);

   type Key_Type is private;

   --  ------------------------------
   --  ------------------------------
   subtype Block_Type is Ada.Streams.Stream_Element_Array (1 .. 16);

   AES_128_Length : constant := 16;
   AES_192_Length : constant := 24;
   AES_256_Length : constant := 32;

   subtype AES_128_Key is Ada.Streams.Stream_Element_Array (1 .. 16);
   subtype AES_192_Key is Ada.Streams.Stream_Element_Array (1 .. 24);
   subtype AES_256_Key is Ada.Streams.Stream_Element_Array (1 .. 32);

   type Word_Block_Type is array (1 .. 4) of Interfaces.Unsigned_32;

   procedure Set_Encrypt_Key (Key  : out Key_Type;
                              Data : in Secret_Key)
     with Pre => Data.Length = 16 or Data.Length = 24 or Data.Length = 32;

   procedure Set_Decrypt_Key (Key  : out Key_Type;
                              Data : in Secret_Key)
     with Pre => Data.Length = 16 or Data.Length = 24 or Data.Length = 32;

   procedure Encrypt (Input  : in Block_Type;
                      Output : out Block_Type;
                      Key    : in Key_Type);
   procedure Encrypt (Input  : in Word_Block_Type;
                      Output : out Word_Block_Type;
                      Key    : in Key_Type);

   procedure Encrypt (Input  : in Ada.Streams.Stream_Element_Array;
                      Output : out Ada.Streams.Stream_Element_Array;
                      Last   : out Ada.Streams.Stream_Element_Offset;
                      Key    : in Key_Type);

   procedure Decrypt (Input  : in Block_Type;
                      Output : out Block_Type;
                      Key    : in Key_Type);

   procedure Decrypt (Input  : in Word_Block_Type;
                      Output : out Word_Block_Type;
                      Key    : in Key_Type);

   type Cipher is tagged limited private;

   --  Set the encryption initialization vector before starting the encryption.
   procedure Set_IV (E  : in out Cipher;
                     IV : in Word_Block_Type);

   --  ------------------------------
   --  AES encoder
   --  ------------------------------
   --  This <b>Encoder</b> translates the (binary) input stream into
   --  an SHA1 hexadecimal stream.  The encoding alphabet is: 0123456789ABCDEF.
   type Encoder is new Cipher and Util.Encoders.Transformer with private;

   --  Set the encryption key to use.
   procedure Set_Key (E    : in out Encoder;
                      Data : in Secret_Key;
                      Mode : in AES_Mode := CBC);

   --  Encodes the binary input stream represented by <b>Data</b> into
   --  an SHA-1 hash output stream <b>Into</b>.
   --
   --  If the transformer does not have enough room to write the result,
   --  it must return in <b>Encoded</b> the index of the last encoded
   --  position in the <b>Data</b> stream.
   --
   --  The transformer returns in <b>Last</b> the last valid position
   --  in the output stream <b>Into</b>.
   --
   --  The <b>Encoding_Error</b> exception is raised if the input
   --  stream cannot be transformed.
   overriding
   procedure Transform (E       : in out Encoder;
                        Data    : in Ada.Streams.Stream_Element_Array;
                        Into    : out Ada.Streams.Stream_Element_Array;
                        Last    : out Ada.Streams.Stream_Element_Offset;
                        Encoded : out Ada.Streams.Stream_Element_Offset);

   --  Finish encoding the input array.
   overriding
   procedure Finish (E    : in out Encoder;
                     Into : in out Ada.Streams.Stream_Element_Array;
                     Last : in out Ada.Streams.Stream_Element_Offset)
     with Pre => Into'Length >= Block_Type'Length,
     Post => Last = Into'First - 1 or Last = Into'First + Block_Type'Length - 1;

   --  ------------------------------
   --  AES encoder
   --  ------------------------------
   --  This <b>Encoder</b> translates the (binary) input stream into
   --  an SHA1 hexadecimal stream.  The encoding alphabet is: 0123456789ABCDEF.
   type Decoder is new Cipher and Util.Encoders.Transformer with private;

   --  Set the decryption key to use.
   procedure Set_Key (E    : in out Decoder;
                      Data : in Secret_Key;
                      Mode : in AES_Mode := CBC);

   --  Encodes the binary input stream represented by <b>Data</b> into
   --  an SHA-1 hash output stream <b>Into</b>.
   --
   --  If the transformer does not have enough room to write the result,
   --  it must return in <b>Encoded</b> the index of the last encoded
   --  position in the <b>Data</b> stream.
   --
   --  The transformer returns in <b>Last</b> the last valid position
   --  in the output stream <b>Into</b>.
   --
   --  The <b>Encoding_Error</b> exception is raised if the input
   --  stream cannot be transformed.
   overriding
   procedure Transform (E       : in out Decoder;
                        Data    : in Ada.Streams.Stream_Element_Array;
                        Into    : out Ada.Streams.Stream_Element_Array;
                        Last    : out Ada.Streams.Stream_Element_Offset;
                        Encoded : out Ada.Streams.Stream_Element_Offset);

   --  Finish encoding the input array.
   overriding
   procedure Finish (E    : in out Decoder;
                     Into : in out Ada.Streams.Stream_Element_Array;
                     Last : in out Ada.Streams.Stream_Element_Offset);

private

   use Interfaces;

   type Block_Key is array (0 .. 59) of Unsigned_32;

   type Key_Type is record
      Key    : Block_Key := (others => 0);
      Rounds : Natural := 0;
   end record;

   type Cipher is limited new Ada.Finalization.Limited_Controlled with record
      IV         : Word_Block_Type;
      Key        : Key_Type;
      Mode       : AES_Mode := CBC;
      Data_Count : Ada.Streams.Stream_Element_Offset := 0;
      Data       : Block_Type;
   end record;

   overriding
   procedure Finalize (Object : in out Cipher);

   type Encoder is new Cipher and Util.Encoders.Transformer with null record;

   type Decoder is new Cipher and Util.Encoders.Transformer with null record;

end Util.Encoders.AES;
