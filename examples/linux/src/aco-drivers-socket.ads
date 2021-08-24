private with SocketCAN; --  Requires GNAT...

package ACO.Drivers.Socket is

   type CAN_Driver is new Driver with private;

   Default_CAN_If_Name : constant String := "can1";

   overriding
   procedure Receive_Message_Blocking
     (This : in out CAN_Driver;
      Msg  :    out ACO.Messages.Message);
   overriding
   procedure Send_Message
     (This : in out CAN_Driver;
      Msg  : in     ACO.Messages.Message);

   overriding
   procedure Initialize (This : in out CAN_Driver) is null
     with OBSOLESCENT => "use Initialie with IF_Name";

   not overriding
   procedure Initialize
     (This : in out CAN_Driver; If_Name : String );

   overriding
   procedure Finalize
     (This : in out CAN_Driver);

   overriding
   function Is_Message_Pending
     (This : CAN_Driver)
      return Boolean;

   overriding
   function Current_Time
     (This : CAN_Driver)
      return Ada.Real_Time.Time;

private

   type CAN_Driver is new Driver with record
      Socket : SocketCAN.Socket_Type;
   end record;

end ACO.Drivers.Socket;
