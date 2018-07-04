package ACO.States is

   pragma Preelaborate;

   --    Initialisation  = 0x00,
   --    Disconnected    = 0x01,
   --    Connecting      = 0x02,
   --    Preparing       = 0x02,
   --    Stopped         = 0x04,
   --    Operational     = 0x05,
   --    Pre_operational = 0x7F,
   --    Unknown_state   = 0x0F

   type State is
     (Initializing,
      Pre_Operational,
      Operational,
      Stopped,
      Unknown_State);

   type State_Transition is record
      Previous : ACO.States.State := ACO.States.Unknown_State;
      Current  : ACO.States.State := ACO.States.Unknown_State;
   end record;

end ACO.States;
