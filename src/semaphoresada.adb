with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Indefinite_Doubly_Linked_Lists; use Ada.Containers;
with Ada.Numerics.Discrete_Random;
with GNAT.Semaphores; use GNAT.Semaphores;


procedure Semaphoresada is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);
   use String_Lists;

   procedure Initalize (Storage_Size : in Integer; Item_Numbers : in Integer; Producers_Count : in Integer; Consumers_Count : in Integer) is
   Storage : List;
   Access_Storage : Counting_Semaphore (1, Default_Ceiling);
   Full_Storage : Counting_Semaphore (Storage_Size, Default_Ceiling);
   Empty_Storage : Counting_Semaphore (0, Default_Ceiling);

   protected AtomicClass is
      procedure AtomicProduced(Total : in Integer);
      procedure AtomicConsumed(Total : in Integer);
      function GetProduced return Integer;
      function GetConsumed return Integer;
   private
      Produced : Integer := 0;
      Consumed : Integer := 0;
   end AtomicClass;

   protected body AtomicClass is

      procedure AtomicProduced (Total : in Integer) is
      begin
         if Produced < Total then
            Produced := Produced + 1;
         end if;
      end AtomicProduced;

      procedure AtomicConsumed (Total : in Integer) is
      begin
         if Consumed < Total then
            Consumed := Consumed + 1;
         end if;
      end AtomicConsumed;

      function GetProduced return Integer is
      begin
         return Produced;
      end GetProduced;

      function GetConsumed return Integer is
      begin
         return Consumed;
      end GetConsumed;

   end AtomicClass;


   type RandRange is range 1 .. 200;

   task type Producer is
      entry Start (ProducerNum : Integer);
   end Producer;

   task body Producer is
      package Rand_Int is new Ada.Numerics.Discrete_Random (RandRange);
      use Rand_Int;
      Id   : Integer;
      Rand : Generator;
      Item : Integer;
   begin
      accept Start (ProducerNum : Integer) do
         Id := ProducerNum;
      end Start;
      Reset (Rand);
      while  AtomicClass.GetProduced < Item_Numbers  loop
         AtomicClass.AtomicProduced(Item_Numbers);
         Full_Storage.Seize;
         Access_Storage.Seize;

         Item := Integer (Random (Rand));
         Storage.Append ("item" & Item'Img);
         Put_Line("---Producer" & Id'Img & " adds item" & Item'Img);

         Access_Storage.Release;
         Empty_Storage.Release;
      end loop;
      Put_Line("Producer" & Id'Img & " finish.");
   end Producer;

   task type Consumer is
      entry Start (ConsumerNum : Integer);
   end Consumer;

   task body Consumer is
      Id : Integer;
   begin
      accept Start (ConsumerNum : Integer) do
         Id := ConsumerNum;
      end Start;
      while  AtomicClass.GetConsumed < Item_Numbers  loop
         AtomicClass.AtomicConsumed(Item_Numbers);
         Empty_Storage.Seize;
         Access_Storage.Seize;

         declare
            Item : String := First_Element (Storage);
         begin
            Put_Line("Consumer" & Id'Img & " took " & Item);
            Storage.Delete_First;

            Access_Storage.Release;
            Full_Storage.Release;
         end;
      end loop;
      Put_Line("Consumer" & Id'Img & " finish.");
   end Consumer;

   type ProdArray is array (Integer range <>) of Producer;
   type ConsArray is array (Integer range <>) of Consumer;
begin
 declare
      Producers : ProdArray (1 .. Producers_Count);
      Consumers : ConsArray (1 .. Consumers_Count);
   begin
      for I in 1 .. Consumers_Count loop
         Consumers (I).Start (I);
      end loop;
      for I in 1 .. Producers_Count loop
         Producers (I).Start (I);
      end loop;
   end;
end Initalize;
begin
   Initalize (4, 12, 2, 5);
end Semaphoresada;
