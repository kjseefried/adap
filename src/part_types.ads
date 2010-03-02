with Bit_Volume; use Bit_Volume;
with Ada.Strings.Unbounded;              use Ada.Strings.Unbounded;
package  Part_Types  is

   type Part_Type_Base is private;
   type Part_Volume_Base is private;
   type Full_Part_Base is private;

   type Part_Type is access Part_Type_Base;
   type Part_Volume is access Part_Volume_Base;
   type Full_Part is access Full_Part_Base;

   type Part_Array is array (Integer range <>) of Full_Part;

   function Make return Full_part;
   function Make return Part_Volume;
   function Make return Part_Type;

   function Make(X,Y,Z,Id  :Integer) return Full_part;
   function Make(X,Y,Z  :Integer) return Part_Volume;
   function Make(ID :Integer) return Part_Type;

   procedure Delete(Inane :in out Full_Part);
   procedure Delete(Inane :in out Part_Volume);
   procedure Delete(Inane :in out Part_Type);


   procedure Get(Src :in Unbounded_String; Id :integer ; Packet :out Full_Part);
   function Get(Src : Unbounded_String; Id :integer)return Full_Part;

   procedure Put(Packet : in  Full_Part; Src : out Unbounded_string);
   function Put(Packet : Full_Part) return Unbounded_String;

   procedure Move_to(Sbj: in out  Full_Part; X,Y,Z :  in Integer);
   procedure Rotate_To (Sbj: in out Full_Part ; X,Y,Z :in Integer); -- FIXME ej impl �n

   procedure Grow(src : in out Full_Part; Dst :  out Full_Part);

   Malformed_Input : exception;


private

      type Rotation_type is  record
      X,Y,Z : Integer;
      end record;

      type Offset_type is  record
         X,Y,Z: Integer;
      end record;

      type Part_Type_Base  is record
         Rot : Rotation_Type;
         Off : Offset_Type;
         Master : Integer;
      end record;

      type Part_Volume_Base is record
         X,Y,Z : Integer;
         Bits : Bit_Volume_Type;
      end record;

      type Full_Part_Base is record
         Genotype : Part_Type;
         Phenotype : Part_Volume;
      end record;


      procedure Rotate_X_Cw(Sbj : in out Full_Part) ; -- FIXME: ej impl �n
      procedure Rotate_Y_Cw(Sbj : in out Full_Part) ;
      procedure Rotate_Z_Cw(Sbj : in out Full_Part);


end Part_Types;
