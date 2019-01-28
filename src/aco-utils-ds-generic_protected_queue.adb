package body ACO.Utils.DS.Generic_Protected_Queue is

   procedure Put_Blocking
      (This : in out Protected_Queue;
       Item : in     Item_Type)
   is
      Success : Boolean;
   begin
      This.Buffer.Put (Item, Success);

      if not Success then
         Ada.Synchronous_Task_Control.Suspend_Until_True (This.Non_Full);
         This.Buffer.Put (Item, Success);
      end if;

      Ada.Synchronous_Task_Control.Set_True (This.Non_Empty);
   end Put_Blocking;

   procedure Put
      (This    : in out Protected_Queue;
       Item    : in     Item_Type;
       Success :    out Boolean)
   is
   begin
      This.Buffer.Put (Item, Success);
   end Put;

   procedure Get_Blocking
      (This : in out Protected_Queue;
       Item :    out Item_Type)
   is
      Success : Boolean;
   begin
      This.Buffer.Get (Item, Success);

      if not Success then
         Ada.Synchronous_Task_Control.Suspend_Until_True (This.Non_Empty);
         This.Buffer.Get (Item, Success);
      end if;

      Ada.Synchronous_Task_Control.Set_True (This.Non_Full);
   end Get_Blocking;

   procedure Get
      (This : in out Protected_Queue;
       Item :    out Item_Type)
   is
      Success : Boolean;
   begin
      This.Buffer.Get (Item, Success);
      Ada.Synchronous_Task_Control.Set_True (This.Non_Full);
   end Get;

   function Count
      (This : Protected_Queue)
       return Natural
   is
   begin
      return This.Buffer.Nof_Items;
   end Count;

   function Is_Empty
      (This : Protected_Queue)
       return Boolean
   is
   begin
      return This.Buffer.Nof_Items = 0;
   end Is_Empty;

   function Is_Full
      (This : Protected_Queue)
       return Boolean
   is
   begin
      return This.Buffer.Nof_Items >= Maximum_Nof_Items;
   end Is_Full;

   protected body Buffer_Type is

      procedure Put
         (Item    : in     Item_Type;
          Success :    out Boolean)
      is
      begin
         if Queue.Is_Full then
            Success := False;
         else
            Success := True;
            Queue.Put (Item);
         end if;
      end Put;

      procedure Get
         (Item    : out Item_Type;
          Success : out Boolean)
      is
      begin
         if Queue.Is_Empty then
            Success := False;
         else
            Success := True;
            Queue.Get (Item);
         end if;
      end Get;

      function Nof_Items return Natural
      is
      begin
         return Queue.Length;
      end Nof_Items;

   end Buffer_Type;

end ACO.Utils.DS.Generic_Protected_Queue;
