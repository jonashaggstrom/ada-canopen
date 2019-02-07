with ACO.Protocols.Service_Data;

package body ACO.Nodes.Remotes is

   overriding
   procedure Set_State
      (This  : in out Remote;
       State : in     ACO.States.State)
   is
   begin
      This.NMT.Request_State (State);

      --  If there is no heartbeat or node guarding, just assume the requested
      --  state is correct...
      if This.Od.Get_Heartbeat_Producer_Period = 0 then
         This.NMT.Set (State);
      end if;
   end Set_State;

   overriding
   function Get_State
      (This  : Remote)
       return ACO.States.State
   is
   begin
      return This.NMT.Get;
   end Get_State;

   overriding
   procedure Start
      (This : in out Remote)
   is
   begin
      This.Handler.Start;
   end Start;

   function Is_Complete
      (This : SDO_Request)
       return Boolean
   is
   begin
      return ACO.SDO_Sessions.Is_Complete (This.Status);
   end Is_Complete;

   procedure Suspend_Until_Result
     (This   : in out SDO_Request;
      Result :    out SDO_Result)
   is
   begin
      if This.Id in ACO.SDO_Sessions.Valid_Endpoint_Nr then
         declare
            Request : Request_Data renames This.Node.SDO.Requests (This.Id);
         begin
            Ada.Synchronous_Task_Control.Suspend_Until_True (Request.Suspension);
            Result := Request.Status;
         end;
      else
         Result := ACO.SDO_Sessions.Error;
      end if;
   end Suspend_Until_Result;

   procedure Suspend_Until_Result
      (This   : in out SDO_Read_Request;
       Result :    out SDO_Result)
   is
   begin
      SDO_Request (This).Suspend_Until_Result (Result);

      case Result is
         when ACO.SDO_Sessions.Complete =>
            This.Get_Entry;

         when ACO.SDO_Sessions.Error =>
            This.Node.SDO.Clear (This.Id);
      end case;
   end Suspend_Until_Result;

   procedure Get_Entry
      (This : in out SDO_Read_Request)
   is
   begin
      This.Node.SDO.Get_Read_Entry (This.Id, This.To_Entry.all);
      This.Node.SDO.Clear (This.Id);
   end Get_Entry;

   function Status
     (This : SDO_Request)
      return SDO_Status
   is
   begin
      if This.Id in ACO.SDO_Sessions.Valid_Endpoint_Nr then
         return This.Node.SDO.Requests (This.Id).Status;
      else
         return ACO.SDO_Sessions.Error;
      end if;
   end Status;

   procedure Write
      (This     : in out Remote;
       Request  : in out SDO_Write_Request'Class;
       Index    : in     ACO.OD_Types.Object_Index;
       Subindex : in     ACO.OD_Types.Object_Subindex;
       An_Entry : in     ACO.OD_Types.Entry_Base'Class)
   is
   begin
      This.SDO.Write_Remote_Entry
         (Node        => This.Id,
          Index       => Index,
          Subindex    => Subindex,
          An_Entry    => An_Entry,
          Endpoint_Id => Request.Id);

      if Request.Id in ACO.SDO_Sessions.Valid_Endpoint_Nr'Range then
         declare
            Req_Data : Request_Data renames This.SDO.Requests (Request.Id);
         begin
            Req_Data.Status := ACO.SDO_Sessions.Pending;
            Req_Data.Operation := Write;
            Ada.Synchronous_Task_Control.Set_False (Req_Data.Suspension);
         end;
      end if;
   end Write;

   overriding
   procedure Write
      (This       : in out Remote;
       Index      : in     ACO.OD_Types.Object_Index;
       Subindex   : in     ACO.OD_Types.Object_Subindex;
       An_Entry   : in     ACO.OD_Types.Entry_Base'Class)
   is
      Request : SDO_Write_Request (This'Access);
   begin
      This.Write (Request  => Request,
                  Index    => Index,
                  Subindex => Subindex,
                  An_Entry => An_Entry);
      declare
         Result : SDO_Result;
      begin
         Request.Suspend_Until_Result (Result);
      end;
   end Write;

   overriding
   procedure Read
      (This     : in out Remote;
       Index    : in     ACO.OD_Types.Object_Index;
       Subindex : in     ACO.OD_Types.Object_Subindex;
       To_Entry :    out ACO.OD_Types.Entry_Base'Class)
   is
      Result : ACO.Nodes.Remotes.SDO_Result;
   begin
      This.Read
         (Index    => Index,
          Subindex => Subindex,
          Result   => Result,
          To_Entry => To_Entry);

      case Result is
         when ACO.SDO_Sessions.Complete =>
            null;

         when ACO.SDO_Sessions.Error =>
            raise Failed_To_Read_Entry_Of_Node
               with Result'Img & " index =" & Index'Img;
      end case;
   end Read;

   procedure Read
      (This     : in out Remote;
       Index    : in     ACO.OD_Types.Object_Index;
       Subindex : in     ACO.OD_Types.Object_Subindex;
       Result   :    out ACO.Nodes.Remotes.SDO_Result;
       To_Entry :    out ACO.OD_Types.Entry_Base'Class)
   is
      Request : ACO.Nodes.Remotes.SDO_Read_Request
         (This'Access, To_Entry'Access);
   begin
      This.Read
         (Request  => Request,
          Index    => Index,
          Subindex => Subindex);

      Request.Suspend_Until_Result (Result);
   end Read;

   procedure Read
      (This     : in out Remote;
       Request  : in out SDO_Read_Request'Class;
       Index    : in     ACO.OD_Types.Object_Index;
       Subindex : in     ACO.OD_Types.Object_Subindex)
   is
   begin
      This.SDO.Read_Remote_Entry
         (Node        => This.Id,
          Index       => Index,
          Subindex    => Subindex,
          Endpoint_Id => Request.Id);

      if Request.Id in ACO.SDO_Sessions.Valid_Endpoint_Nr'Range then
         declare
            Req_Data : Request_Data renames This.SDO.Requests (Request.Id);
         begin
            Req_Data.Status := ACO.SDO_Sessions.Pending;
            Req_Data.Operation := Read;
            Ada.Synchronous_Task_Control.Set_False (Req_Data.Suspension);
         end;
      end if;
   end Read;

   function Generic_Read
      (This     : in out Remote;
       Index    : ACO.OD_Types.Object_Index;
       Subindex : ACO.OD_Types.Object_Subindex)
       return Entry_T
   is
      An_Entry : aliased Entry_T;
      Request  : ACO.Nodes.Remotes.SDO_Read_Request
         (This'Access, An_Entry'Access);
      Result   : ACO.Nodes.Remotes.SDO_Result;
   begin
      This.Read
         (Request  => Request,
          Index    => Index,
          Subindex => Subindex);

      Request.Suspend_Until_Result (Result);

      if not Request.Is_Complete then
         raise Failed_To_Read_Entry_Of_Node
            with Result'Img & " index =" & Index'Img;
      end if;

      return An_Entry;
   end Generic_Read;

   procedure Set_Heartbeat_Timeout
      (This    : in out Remote;
       Timeout : in     Natural)
   is
   begin
      This.NMT.Set_Heartbeat_Timeout (Timeout);
   end Set_Heartbeat_Timeout;

   procedure On_Message_Dispatch
      (This : in out Remote;
       Msg  : in     ACO.Messages.Message)
   is
   begin
      if This.NMT.Is_Valid (Msg) then
         This.NMT.Message_Received (Msg);
      elsif This.EC.Is_Valid (Msg) then
         This.EC.Message_Received (Msg);
      elsif This.SDO.Is_Valid (Msg) then
         This.SDO.Message_Received (Msg);
      end if;
   end On_Message_Dispatch;

   procedure Periodic_Actions
      (This  : in out Remote;
       T_Now : in     Ada.Real_Time.Time)
   is
   begin
      This.NMT.Periodic_Actions (T_Now);
      This.SDO.Periodic_Actions (T_Now);
   end Periodic_Actions;

   overriding
   procedure Result_Callback
     (This    : in out Remote_Client;
      Session : in     ACO.SDO_Sessions.SDO_Session;
      Result  : in     ACO.SDO_Sessions.SDO_Result)
   is
      Request : Request_Data renames This.Requests (Session.Endpoint.Id);
   begin
      Request.Status := Result;

      case Request.Operation is
         when Write =>
            This.Clear (Session.Endpoint.Id);

         when Read =>
            null;
      end case;

      Ada.Synchronous_Task_Control.Set_True (Request.Suspension);

      This.Od.Events.Node_Events.Put
        ((Event      => ACO.Events.SDO_Status_Update,
          SDO_Status => (Endpoint_Id => Session.Endpoint.Id,
                         Result      => Result)));
   end Result_Callback;

   overriding
   function Tx_CAN_Id
      (This      : Remote_Client;
       Parameter : ACO.SDO_Sessions.SDO_Parameters)
       return ACO.Messages.Id_Type
   is
      (Parameter.CAN_Id_C2S);

   overriding
   function Rx_CAN_Id
      (This      : Remote_Client;
       Parameter : ACO.SDO_Sessions.SDO_Parameters)
       return ACO.Messages.Id_Type
   is
      (Parameter.CAN_Id_S2C);

   overriding
   function Get_Endpoint
      (This      : Remote_Client;
       Rx_CAN_Id : ACO.Messages.Id_Type)
       return ACO.SDO_Sessions.Endpoint_Type
   is
      use type ACO.Messages.Id_Type;
      --  Clients always initiate a session and a remote client always use the
      --  default mandatory Id's, meaning we should make sure we use the same
      --  endpoint as when we sent the initial request...
      Endpoint : constant ACO.SDO_Sessions.Endpoint_Type :=
         This.Get_Endpoint (Server_Node => This.Id);
   begin
      if This.Rx_CAN_Id (Endpoint.Parameters) = Rx_CAN_Id then
         return Endpoint;
      else
         return ACO.SDO_Sessions.No_Endpoint;
      end if;
   end Get_Endpoint;

   overriding
   function Get_Endpoint
      (This        : Remote_Client;
       Server_Node : ACO.Messages.Node_Nr)
       return ACO.SDO_Sessions.Endpoint_Type
   is
      use type ACO.Messages.Id_Type;
      --  As a remote client we only know the OD of the server, therefore we can
      --  use any of the C2S-Id's of the server.
      --  But the mandatory Server-Rx-Id is a good choice...
      Tx_CAN_Id : constant ACO.Messages.CAN_Id_Type :=
         (As_Id => False,
          Code  => ACO.Protocols.Service_Data.SDO_C2S_Id,
          Node  => Server_Node);
      I : ACO.SDO_Sessions.Endpoint_Nr :=
         ACO.SDO_Sessions.Valid_Endpoint_Nr'First;
   begin
      for P of This.Od.Get_SDO_Server_Parameters loop
         if This.Tx_CAN_Id (P) = Tx_CAN_Id.Id then
            return (Id => I, Parameters => P);
         end if;
         I := ACO.SDO_Sessions.Endpoint_Nr'Succ (I);
      end loop;

      return ACO.SDO_Sessions.No_Endpoint;
   end Get_Endpoint;

end ACO.Nodes.Remotes;
