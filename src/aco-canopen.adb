with ACO.Log;
with ACO.Messages; use ACO.Messages;
with Ada.Exceptions;

package body ACO.CANopen is

   procedure Put
      (This : in out Handler;
       Msg  : in     ACO.Messages.Message)
   is
      Success : Boolean;
   begin
      This.Messages.Put (Msg, Success);

      if not Success then
         ACO.Log.Put_Line (ACO.Log.Warning, "Transmit buffer is full");
      end if;
   end Put;

   procedure Periodic_Actions
      (This  : in out Handler;
       T_Now : in     Ada.Real_Time.Time)
   is
      Msg : ACO.Messages.Message;
   begin
      while This.Driver.Is_Message_Pending loop
         This.Driver.Receive_Message_Blocking (Msg);

         This.Events.Handler_Events.Update
           ((Event => ACO.Events.Received_Message,
             Msg   => Msg));
      end loop;

      This.Events.Handler_Events.Update
        ((Event        => ACO.Events.Tick,
          Current_Time => T_Now));

      while not This.Messages.Is_Empty loop
         This.Messages.Get (Msg);
         This.Driver.Send_Message (Msg);
      end loop;
   end Periodic_Actions;

   function Current_Time
     (This : Handler)
      return Ada.Real_Time.Time
   is
     (This.Driver.Current_Time);

   procedure Start
      (This : in out Handler)
   is
   begin
      Ada.Synchronous_Task_Control.Set_True (This.Suspension);
   end Start;

   task body Periodic_Task
   is

      Next_Release : Ada.Real_Time.Time;
   begin
      Ada.Synchronous_Task_Control.Suspend_Until_True (This.Suspension);

      ACO.Log.Put_Line (ACO.Log.Debug, "Starting periodic worker task...");
      Next_Release := This.Current_Time;

      loop
         begin
            This.Periodic_Actions (T_Now => Next_Release);
         exception
            when E : others =>
               ACO.Log.Put_Line
                  (ACO.Log.Warning,
                   "EXCEPTION while executing periodic actions: " &
                   Ada.Exceptions.Exception_Information (E));
         end;

         Next_Release := Next_Release + To_Time_Span(Period_Dur.all);
         delay until Next_Release;
      end loop;
   end Periodic_Task;

end ACO.CANopen;
