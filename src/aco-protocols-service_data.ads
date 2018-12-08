with Ada.Real_Time;
with ACO.Messages;
with ACO.OD;
with ACO.OD_Types;
with ACO.Drivers;
with ACO.States;
with ACO.SDO_Sessions;

private with ACO.Log;
private with ACO.Utils.Generic_Alarms;
private with ACO.Configuration;
private with ACO.SDO_Commands;

package ACO.Protocols.Service_Data is

   use ACO.Messages;
   use ACO.OD_Types;
   use ACO.SDO_Sessions;

   SDO_S2C_Id : constant Function_Code := 16#B#;
   SDO_C2S_Id : constant Function_Code := 16#C#;

   type SDO
      (Od     : not null access ACO.OD.Object_Dictionary'Class;
       Driver : not null access ACO.Drivers.Driver'Class)
   is new Protocol with private;

   procedure Message_Received
     (This : in out SDO;
      Msg  : in     Message);

   procedure Periodic_Actions
      (This  : in out SDO;
       T_Now : in     Ada.Real_Time.Time);

   procedure Write_Remote_Entry
      (This        : in out SDO;
       Node        : in     Node_Nr;
       Index       : in     Object_Index;
       Subindex    : in     Object_Subindex;
       An_Entry    : in     Entry_Base'Class;
       Endpoint_Id :    out Endpoint_Nr);

   procedure Read_Remote_Entry
      (This        : in out SDO;
       Node        : in     Node_Nr;
       Index       : in     Object_Index;
       Subindex    : in     Object_Subindex;
       Endpoint_Id :    out Endpoint_Nr);

   function Get_Status
      (This        : SDO;
       Endpoint_Id : ACO.SDO_Sessions.Valid_Endpoint_Nr)
       return ACO.SDO_Sessions.SDO_Status;

   procedure Get_Read_Entry
      (This        : in out SDO;
       Endpoint_Id : in     ACO.SDO_Sessions.Valid_Endpoint_Nr;
       Read_Entry  : in out Entry_Base'Class)
      with Pre => This.Get_Status (Endpoint_Id) = Complete;

   procedure Clear
      (This        : in out SDO;
       Endpoint_Id : in     ACO.SDO_Sessions.Valid_Endpoint_Nr)
      with Post => This.Get_Status (Endpoint_Id) = Pending;

private


   type Error_Type is
      (Nothing,
       Unknown,
       General_Error,
       Invalid_Value_For_Parameter,
       Toggle_Bit_Not_Altered,
       SDO_Protocol_Timed_Out,
       Command_Specifier_Not_Valid_Or_Unknown,
       Object_Does_Not_Exist_In_The_Object_Dictionary,
       Attempt_To_Read_A_Write_Only_Object,
       Attempt_To_Write_A_Read_Only_Object,
       Failed_To_Transfer_Or_Store_Data,
       Failed_To_Transfer_Or_Store_Data_Due_To_Local_Control);

   Abort_Code : constant array (Error_Type) of ACO.SDO_Commands.Abort_Code_Type :=
      (Nothing                                               => 16#0000_0000#,
       Unknown                                               => 16#0000_0000#,
       General_Error                                         => 16#0800_0000#,
       Invalid_Value_For_Parameter                           => 16#0609_0030#,
       Toggle_Bit_Not_Altered                                => 16#0503_0000#,
       SDO_Protocol_Timed_Out                                => 16#0504_0000#,
       Command_Specifier_Not_Valid_Or_Unknown                => 16#0504_0001#,
       Object_Does_Not_Exist_In_The_Object_Dictionary        => 16#0602_0000#,
       Attempt_To_Read_A_Write_Only_Object                   => 16#0601_0001#,
       Attempt_To_Write_A_Read_Only_Object                   => 16#0601_0002#,
       Failed_To_Transfer_Or_Store_Data                      => 16#0800_0020#,
       Failed_To_Transfer_Or_Store_Data_Due_To_Local_Control => 16#0800_0021#);

   overriding
   procedure Initialize (This : in out SDO);

   overriding
   procedure Finalize (This : in out SDO);

   package Alarms is new ACO.Utils.Generic_Alarms
      (Configuration.Max_Nof_Simultaneous_SDO_Sessions);

   type Alarm (SDO_Ref : access SDO'Class := null) is new Alarms.Alarm_Type with
      record
         Id : Endpoint_Nr := No_Endpoint_Id;
      end record;

   overriding
   procedure Signal
      (This  : access Alarm;
       T_Now : in     Ada.Real_Time.Time);

   type Alarm_Array is array (Valid_Endpoint_Nr'Range) of aliased Alarm;

   type SDO
      (Od     : not null access ACO.OD.Object_Dictionary'Class;
       Driver : not null access ACO.Drivers.Driver'Class) is new Protocol (Od) with
   record
      Sessions : Session_Manager;
      Timers   : Alarms.Alarm_Manager;
      Alarms   : Alarm_Array := (others => (SDO'Access, No_Endpoint_Id));
   end record;

   overriding
   procedure On_State_Change
     (This     : in out SDO;
      Previous : in     ACO.States.State;
      Current  : in     ACO.States.State);

   procedure SDO_Log
     (This    : in out SDO;
      Level   : in     ACO.Log.Log_Level;
      Message : in     String);

   procedure Start_Alarm
      (This     : in out SDO;
       Endpoint : in     Endpoint_Type);

   procedure Stop_Alarm
      (This     : in out SDO;
       Endpoint : in     Endpoint_Type);

   procedure Message_Received_For_Server
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Server_Download_Init
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Server_Download_Segment
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Server_Upload_Init
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Server_Upload_Segment
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Message_Received_For_Client
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Client_Download_Init
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Client_Upload_Init
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Client_Upload_Segment
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Client_Download_Segment
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Abort_All
      (This     : in out SDO;
       Msg      : in     Message;
       Endpoint : in     Endpoint_Type);

   procedure Write
      (This    : in out SDO;
       Index   : in     ACO.OD_Types.Entry_Index;
       Data    : in     Data_Array;
       Error   :    out Error_Type);

   procedure Send_SDO
      (This     : in out SDO;
       Endpoint : in     Endpoint_Type;
       Raw_Data : in     Msg_Data);

   procedure Client_Send_Data_Segment
      (This     : in out SDO;
       Endpoint : in     Endpoint_Type;
       Toggle   : in     Boolean);

   procedure Send_Abort
      (This     : in out SDO;
       Endpoint : in     Endpoint_Type;
       Error    : in     Error_Type;
       Index    : in     ACO.OD_Types.Entry_Index := (0,0));

end ACO.Protocols.Service_Data;
