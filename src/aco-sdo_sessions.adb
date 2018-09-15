package body ACO.SDO_Sessions is

   function Get_Endpoint
      (CAN_Id         : Id_Type;
       Client_CAN_Ids : SDO_CAN_Id_Array;
       Server_CAN_Ids : SDO_CAN_Id_Array)
       return Endpoint_Type
   is
      I : Endpoint_Nr := Valid_Endpoint_Nr'First;
   begin
      for Client_CAN_Id of Client_CAN_Ids loop
         if Client_CAN_Id.S2C = CAN_Id then
            return (Id => I, Role => Client, CAN_Id => Client_CAN_Id);
         end if;
         I := Endpoint_Nr'Succ (I);
      end loop;

      for Server_CAN_Id of Server_CAN_Ids loop
         if Server_CAN_Id.C2S = CAN_Id then
            return (Id => I, Role => Server, CAN_Id => Server_CAN_Id);
         end if;
         I := Endpoint_Nr'Succ (I);
      end loop;

      return No_Endpoint;
   end Get_Endpoint;

   function Create_Download
      (Endpoint  : Endpoint_Type;
       Index     : ACO.OD_Types.Entry_Index;
       Nof_Bytes : Natural)
       return SDO_Session
   is
      ((Service   => Download,
        Endpoint  => Endpoint,
        Index     => Index,
        Nof_Bytes => Nof_Bytes,
        Count     => 0,
        Toggle    => False));

   procedure Put
      (This    : in out Session_Manager;
       Session : in     SDO_Session)
   is
   begin
      This.List (Session.Endpoint.Id) := Session;
   end Put;

   function Get
      (This : Session_Manager;
       Id   : Valid_Endpoint_Nr)
       return SDO_Session
   is
      (This.List (Id));

   function Service
      (This : Session_Manager;
       Id   : Valid_Endpoint_Nr)
       return Services
   is
      (This.List (Id).Service);

   procedure Clear
      (This : in out Session_Manager;
       Id   : in     Valid_Endpoint_Nr)
   is
   begin
      This.List (Id) := (None, No_Endpoint);
      This.Buffers (Id).Next := This.Buffers (Id).Buffer'First;
   end Clear;

   procedure Buffer
      (This : in out Session_Manager;
       Id   : in     Valid_Endpoint_Nr;
       Data : in     Data_Array)
   is
      Next : Natural renames This.Buffers (Id).Next;
   begin
      This.Buffers (Id).Buffer (Next .. Next + Data'Length - 1) := Data;
      Next := Next + Data'Length;
   end Buffer;

   function Get_Buffer_Data
      (This : Session_Manager;
       Id   : Valid_Endpoint_Nr)
       return Data_Array
   is
      subtype Returned is Natural range
         This.Buffers (Id).Buffer'First .. This.Buffers (Id).Next - 1;
   begin
      return This.Buffers (Id).Buffer (Returned'Range);
   end Get_Buffer_Data;

end ACO.SDO_Sessions;
