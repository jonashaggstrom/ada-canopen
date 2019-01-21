with Ada.Finalization;
with ACO.States;
with ACO.Messages;
with ACO.Events;
with ACO.OD;

package ACO.Protocols is

   type Protocol (Od : not null access ACO.OD.Object_Dictionary'Class) is
      abstract new Ada.Finalization.Limited_Controlled with private;

   type Protocol_Access is access all Protocol'Class;

   function Is_Valid
      (This : in out Protocol;
       Msg  : in     ACO.Messages.Message)
       return Boolean is abstract;

   procedure On_State_Change
     (This     : in out Protocol;
      Previous : in     ACO.States.State;
      Current  : in     ACO.States.State) is abstract;

private

   type Node_State_Change_Subscriber (Protocol_Ref : not null access Protocol'Class) is
      new ACO.Events.Node_State.Subscriber with null record;

   overriding
   procedure Update
     (This : access Node_State_Change_Subscriber;
      Data : in     ACO.States.State_Transition);

   overriding
   procedure Initialize (This : in out Protocol);

   overriding
   procedure Finalize (This : in out Protocol);

   type Protocol (Od : not null access ACO.OD.Object_Dictionary'Class) is
      abstract new Ada.Finalization.Limited_Controlled with
   record
      Node_State_Change_Indication : aliased Node_State_Change_Subscriber (Protocol'Access);
   end record;

end ACO.Protocols;
